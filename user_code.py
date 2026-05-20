
MAX_CALLS=10

import multiprocessing as mp

# Устанавливаем метод запуска процессов
try:
	mp.set_start_method("fork")
except RuntimeError:
	pass

from py4godot.classes import gdclass
from py4godot.classes.Node2D import Node2D
from py4godot.classes.core import Vector2
from multiprocessing import Process, Pipe, Manager
import io, sys, traceback, time, itertools

player_global = None
laptop_global = None
enemies_global = None

EXEC_TIMEOUT = 0.1

manager = None
shared_state = None

_child_req_counter = itertools.count(1)


@gdclass
class user_code(Node2D):
	def delta(self, player, laptop, enemies):
		global player_global, laptop_global, enemies_global
		player_global = player
		laptop_global = laptop
		enemies_global = enemies
		self.run_main(laptop)

	def run_main(self, laptop):
		parent_conn, child_conn = Pipe(duplex=True)
		global manager, shared_state

		if manager is None:
			manager = Manager()
			shared_state = manager.dict()

		p = Process(target=_sandbox_entry, args=(child_conn, shared_state), daemon=True)
		p.start()
		child_conn.close()

		start = time.time()
		result = None
		call_count = 0
		allowed_rpc = {"set_direction", "get_direction", "try_pass"}

		while True:
			if parent_conn.poll(0.001):
				try:
					msg = parent_conn.recv()
				except Exception:
					break

				if not isinstance(msg, dict):
					continue

				mtype = msg.get("type")
				if mtype == "rpc_request":
					reqid = msg.get("id")
					name = msg.get("name")
					args = msg.get("args", [])

					call_count += 1
					if call_count > MAX_CALLS:
						try:
							parent_conn.send({"type": "rpc_reply", "id": reqid, "result": None, "error": "functions_call_limit_exceeded"})
						except Exception:
							pass
						try:
							p.terminate()
						except Exception:
							pass
						p.join()
						laptop.call("logging", "\nERROR: call limit exceeded\n")
						return

					try:
						if name == "set_direction":
							if isinstance(args, (list, tuple)) and len(args) >= 2:
								player_global.set("direction", list_to_vector(args))
								parent_conn.send({"type": "rpc_reply", "id": reqid, "result": True})
							else:
								parent_conn.send({"type": "rpc_reply", "id": reqid, "result": False, "error": "bad_args"})
						elif name == "get_direction":
							val = [player_global.get("direction").x, player_global.get("direction").y]
							parent_conn.send({"type": "rpc_reply", "id": reqid, "result": val})
						elif name == "try_pass":
							if isinstance(args, (list, tuple)) and len(args) == 1:
								try:
									children = enemies_global.call("get_children")
									enemy = children[0] if children else None
									if enemy:
										result = enemy.call("try_pass", args[0])
										parent_conn.send({"type": "rpc_reply", "id": reqid, "result": result})
									else:
										error_msg = "no_enemy: нет врагов на сцене"
										parent_conn.send({"type": "rpc_reply", "id": reqid, "result": False, "error": error_msg})
										# Немедленно выводим ошибку в консоль Godot
										laptop.call("logging", f"[color=red]RPC Error: {error_msg}[/color]\n")
								except Exception as e:
									error_msg = f"exception in try_pass: {e}"
									parent_conn.send({"type": "rpc_reply", "id": reqid, "result": False, "error": error_msg})
									laptop.call("logging", f"[color=red]{error_msg}[/color]\n")
									# Также выводим traceback
									tb = traceback.format_exc()
									laptop.call("logging", f"[color=red]{tb}[/color]\n")
							else:
								parent_conn.send({"type": "rpc_reply", "id": reqid, "result": False, "error": "bad_args"})
						else:
							parent_conn.send({"type": "rpc_reply", "id": reqid, "result": None, "error": "unknown_rpc"})
					except Exception as e:
						error_msg = f"exception_in_parent: {e}"
						try:
							parent_conn.send({"type": "rpc_reply", "id": reqid, "result": None, "error": error_msg})
						except Exception:
							pass
						laptop.call("logging", f"[color=red]{error_msg}\n{traceback.format_exc()}[/color]\n")
					continue

				elif mtype == "final":
					result = msg
					break
				else:
					if "output" in msg and "commands" in msg:
						result = msg
						break
					continue

			if time.time() - start > EXEC_TIMEOUT:
				try:
					p.terminate()
				except Exception:
					pass
				p.join()
				laptop.call("logging", "\nERROR: Execution timed out\n")
				return

			if not p.is_alive():
				break

		p.join()

		try:
			if result is None:
				laptop.call("logging", "\nERROR: no final payload from sandbox\n")
			else:
				out = result.get("output", "")
				cmds = result.get("commands", [])
				if out:
					laptop.call("logging", out)
				if cmds:
					laptop.call("logging", "\nSandbox commands: {}\n".format(cmds))
		except Exception:
			pass
		return


def _format_user_traceback(exc_info):
	return "".join(traceback.format_exception(*exc_info))


def _sandbox_entry(conn, shared_state):
	output = io.StringIO()
	old_stdout, old_stderr = sys.stdout, sys.stderr
	sys.stdout = sys.stderr = output

	commands = []

	def _next_req_id():
		return next(_child_req_counter)

	def rpc_call(name, args=None):
		if args is None:
			args = []
		reqid = _next_req_id()
		try:
			conn.send({"type": "rpc_request", "name": name, "args": args, "id": reqid})
		except Exception:
			print("Sandbox: failed to send rpc request", name)
			return None
		try:
			reply = conn.recv()
		except Exception:
			print("Sandbox: no reply for rpc", name)
			return None
		if isinstance(reply, dict) and reply.get("type") == "rpc_reply" and reply.get("id") == reqid:
			return reply.get("result")
		return None

	def _sandbox_get_direction():
		res = rpc_call("get_direction", [])
		if isinstance(res, (list, tuple)) and len(res) >= 2:
			return [res[0], res[1]]
		return [0, 0]

	def _sandbox_set_direction(arr):
		try:
			rpc_call("set_direction", [float(arr[0]), float(arr[1])])
		except Exception:
			print("Sandbox: invalid set_direction argument:", arr)

	def _sandbox_try_pass(passw):
		try:
			# ---- ИЗМЕНЕНИЕ: автоматическое преобразование в строку ----
			return rpc_call("try_pass", [str(passw)])
		except Exception as e:
			# Логируем ошибку в вывод (попадёт в консоль Godot)
			print(f"Error in try_pass({passw!r}): {e}")
			return False

	# Внедряем функции в глобальное пространство песочницы
	g = globals()
	g["set_direction"] = _sandbox_set_direction
	g["get_direction"] = _sandbox_get_direction
	g["try_pass"] = _sandbox_try_pass
	g["storage"] = shared_state

	try:
		try:
			main()
		except Exception:
			output.write("\nERROR in user code:\n")
			output.write(_format_user_traceback(sys.exc_info()))
	finally:
		payload = {"type": "final", "output": output.getvalue(), "commands": commands}
		sys.stdout, sys.stderr = old_stdout, old_stderr
		try:
			conn.send(payload)
		except Exception:
			pass
		try:
			conn.close()
		except Exception:
			pass


def list_to_vector(arr):
	vec = Vector2.new0()
	vec.x = arr[0]
	vec.y = arr[1]
	return vec
def main():
	for i in range(10,90):
		try_pass(i)
