# code.py
import sys
import os
import threading
import queue
import time
import io
import traceback

# Настройки
MAX_CALLS = 10
EXEC_TIMEOUT = 10.0

# Глобальные ссылки на объекты Godot
player_global = None
laptop_global = None
enemies_global = None
shared_state = {}

# Импорты py4godot (будут работать только в главном процессе)
from py4godot.classes import gdclass
from py4godot.classes.Node2D import Node2D
from py4godot.classes.core import Vector2

def list_to_vector(arr):
	vec = Vector2.new0()
	vec.x = arr[0]
	vec.y = arr[1]
	return vec

@gdclass
class user_code(Node2D):
	def delta(self, player, laptop, enemies):
		global player_global, laptop_global, enemies_global
		player_global = player
		laptop_global = laptop
		enemies_global = enemies
		self.run_main(laptop)

	def run_main(self, laptop):
		global shared_state

		# Получаем чистый пользовательский код из редактора
		user_code = laptop.call("get_code_text")
		if not user_code or user_code.strip() == "":
			laptop.call("logging", "[color=yellow]No user code to execute[/color]\n")
			return

		request_queue = queue.Queue()
		call_count = 0
		thread_error = []  # для перехвата ошибок из потока

		def user_thread():
			output_capture = io.StringIO()
			old_stdout, old_stderr = sys.stdout, sys.stderr
			sys.stdout = sys.stderr = output_capture

			def _set_direction(arr):
				rid = f"req_{threading.get_ident()}_{time.time()}"
				resp_q = queue.Queue()
				request_queue.put(("set_direction", arr, rid, resp_q))
				return resp_q.get()

			def _get_direction():
				rid = f"req_{threading.get_ident()}_{time.time()}"
				resp_q = queue.Queue()
				request_queue.put(("get_direction", None, rid, resp_q))
				return resp_q.get()

			def _try_pass(password):
				rid = f"req_{threading.get_ident()}_{time.time()}"
				resp_q = queue.Queue()
				request_queue.put(("try_pass", str(password), rid, resp_q))
				return resp_q.get()

			user_globals = {
				"set_direction": _set_direction,
				"get_direction": _get_direction,
				"try_pass": _try_pass,
				"storage": shared_state,
			}

			try:
				exec(user_code, user_globals)
				if "main" in user_globals:
					user_globals["main"]()
				else:
					output_capture.write("\n[GAME] main() function not defined\n")
			except Exception:
				output_capture.write("\nERROR in user code:\n")
				output_capture.write(traceback.format_exc())
			finally:
				sys.stdout, sys.stderr = old_stdout, old_stderr
				request_queue.put(("__final__", output_capture.getvalue(), None, None))

		thread = threading.Thread(target=user_thread, daemon=True)
		thread.start()

		start_time = time.time()
		final_output = ""

		while True:
			# Ждём либо сообщение из очереди, либо поток перестаёт быть живым
			try:
				msg = request_queue.get(timeout=0.1)
			except queue.Empty:
				# Проверяем таймаут
				if time.time() - start_time > EXEC_TIMEOUT:
					laptop.call("logging", "\nERROR: Execution timed out\n")
					break
				# Если поток не живой, а сообщения нет — что-то пошло не так
				if not thread.is_alive():
					laptop.call("logging", "\nERROR: sandbox thread died unexpectedly\n")
					break
				continue

			cmd = msg[0]
			if cmd == "__final__":
				final_output = msg[1]
				break
			elif cmd == "set_direction":
				arr, rid, resp_q = msg[1], msg[2], msg[3]
				call_count += 1
				if call_count > MAX_CALLS:
					resp_q.put(False)
				else:
					try:
						if isinstance(arr, list) and len(arr) >= 2:
							player_global.set("direction", list_to_vector(arr))
							resp_q.put(True)
						else:
							resp_q.put(False)
					except Exception as e:
						laptop.call("logging", f"[color=red]set_direction error: {e}[/color]\n")
						resp_q.put(False)
			elif cmd == "get_direction":
				call_count += 1
				if call_count > MAX_CALLS:
					msg[3].put([0, 0])
				else:
					val = [player_global.get("direction").x, player_global.get("direction").y]
					msg[3].put(val)
			elif cmd == "try_pass":
				password, rid, resp_q = msg[1], msg[2], msg[3]
				call_count += 1
				if call_count > MAX_CALLS:
					resp_q.put(False)
				else:
					try:
						children = enemies_global.call("get_children")
						enemy = children[0] if children else None
						if enemy:
							result = enemy.call("try_pass", password)
							resp_q.put(result)
						else:
							laptop.call("logging", "[color=red]RPC Error: no_enemy[/color]\n")
							resp_q.put(False)
					except Exception as e:
						laptop.call("logging", f"[color=red]exception in try_pass: {e}\n{traceback.format_exc()}[/color]\n")
						resp_q.put(False)

		if final_output:
			laptop.call("logging", final_output)
		else:
			# Если ничего не получили — не выводим повторную ошибку, она уже залогирована
			pass
