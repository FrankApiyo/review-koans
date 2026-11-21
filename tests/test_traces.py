from pathlib import Path

import pytest

import traces
from traces import mask, scrub

ROOT = Path("/work/review-koans")

COUNTER = """\
exit 1
--- stdout

[error] GenServer Counter terminating
** (ArithmeticError) bad argument in arithmetic expression
    :erlang.+(1, "two")
    traces/01_counter.exs:12: Counter.handle_call/3
    (stdlib 7.3) gen_server.erl:2470: :gen_server.try_handle_call/4
    (stdlib 7.3) gen_server.erl:2499: :gen_server.handle_msg/3
    (stdlib 7.3) proc_lib.erl:333: :proc_lib.init_p_do_apply/3
Last message (from #PID<0.94.0>): {:bump, "two"}
State: 1
Client #PID<0.94.0> is alive

    (stdlib 7.3) gen.erl:262: :gen.do_call/4
    (elixir 1.19.5) lib/gen_server.ex:1139: GenServer.call/3
    traces/01_counter.exs:20: (file)
    (elixir 1.19.5) src/elixir_compiler.erl:81: :elixir_compiler.dispatch/4
    (elixir 1.19.5) src/elixir_compiler.erl:56: :elixir_compiler.compile/4
--- stderr
** (exit) exited in: GenServer.call(Counter, {:bump, "two"}, 5000)
    ** (EXIT) an exception was raised:
        ** (ArithmeticError) bad argument in arithmetic expression
            :erlang.+(1, "two")
            traces/01_counter.exs:12: Counter.handle_call/3
            (stdlib 7.3) gen_server.erl:2470: :gen_server.try_handle_call/4
    (elixir 1.19.5) lib/gen_server.ex:1142: GenServer.call/3
    traces/01_counter.exs:20: (file)
"""

CART = """\
exit 1
--- stdout
--- stderr
traces/cart.mjs:4
  return lines.reduce((sum, line) => sum + prices.get(line.sku).valueOf() * line.qty, 0)
                                                                ^

TypeError: Cannot read properties of undefined (reading 'valueOf')
    at traces/cart.mjs:4:65
    at Array.reduce (<anonymous>)
    at total (traces/cart.mjs:4:16)
    at traces/cart.mjs:7:1
    at ModuleJob.run (node:internal/modules/esm/module_job:437:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:639:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v25.9.0
"""

BOOM = """\
exit 1
--- stdout
reporting
--- stderr
traces/boom.ts:2
  return order.items.length
                     ^

TypeError: Cannot read properties of undefined (reading 'length')
    at itemCount (traces/boom.ts:2:22)
    at report (traces/boom.ts:7:20)
    at traces/boom.ts:11:13
    at ModuleJob.run (node:internal/modules/esm/module_job:437:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:639:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v25.9.0
"""

UNHANDLED = """\
exit 1
--- stdout
order o-17 complete
--- stderr
traces/unhandled.ts:4
    throw new Error(`invalid recipient: ${email}`)
          ^

Error: invalid recipient: ann.example.com
    at sendReceipt (traces/unhandled.ts:4:11)

Node.js v25.9.0
"""

LIVE = """\
[error] GenServer #PID<0.512.0> terminating
** (FunctionClauseError) no function clause matching in Board.handle_event/3
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GOjFmOiYZVJevRSD", event: "event", \
payload: %{"event" => "mark"}, ref: "4", join_ref: "1"}
State: %{id: "phx-GOjFmOiYZVJevRSD", monitor: #Reference<0.3104.1.20>, port: #Port<0.7>}
"""

LIVE_MARKUP = (
    '<div id="phx-GOjFtvxTWuABD-_8" data-phx-main>'
    '<button phx-click="pick" phx-value-id="2" phx-value-identifier="tea">tea</button>'
    '<form phx-submit="save" phx-change="validate"></form></div>'
)

ROUTES = (
    "** (Phoenix.Router.NoRouteError) no route found for GET /ch07/notes/1 (Support.Router)\n"
    '    live "/ch08/notebooks/:id/edit", Course.Ch08.NotebookLive.Edit\n'
)
HOME = Path("/srv/people/ada")
FILESYSTEM_ROOTS = {
    "file_url": "file:///opt/elsewhere/",
    "users": "/" + "Users/ada/",
    "home": "/" + "home/ada/",
    "private": "/private/var/tmp/",
    "var_folders": "/var/folders/xy/T/",
    "tmp": "/tmp/",
    "opt": "/opt/homebrew/Cellar/erlang/",
    "usr": "/usr/local/lib/erlang/",
    "nix": "/nix/store/",
    "path_home": f"{HOME}/",
    "repo_root": f"{ROOT}/",
}


def test_scrub_removes_root_paths_file_urls_and_timestamps():
    raw = (
        "10:35:01.627 [error] GenServer Counter terminating\n"
        "    /work/review-koans/elixir/traces/01_counter.exs:12: Counter.handle_call/3\n"
        "    at file:///work/review-koans/elixir/traces/cart.mjs:4:65\n"
        "see /work/review-koans/tools/links.txt and file:///work/review-koans/README.md\n"
        "a clock 10:35:01.627 mid-line stays\n"
    )

    assert scrub(raw, ROOT) == (
        "[error] GenServer Counter terminating\n"
        "    traces/01_counter.exs:12: Counter.handle_call/3\n"
        "    at traces/cart.mjs:4:65\n"
        "see tools/links.txt and README.md\n"
        "a clock 10:35:01.627 mid-line stays\n"
    )


def test_mask_tolerates_otp_patch_frames_and_pid_drift():
    patched = COUNTER.replace("(stdlib 7.3) gen_server.erl:2470", "(stdlib 7.4) gen_server.erl:2481")
    drifted = patched.replace("#PID<0.94.0>", "#PID<0.97.0>")

    assert drifted != COUNTER
    assert mask(drifted) == mask(COUNTER)


def test_mask_collapses_an_extra_runtime_frame():
    extra = "    (elixir 1.19.5) src/elixir_lexical.erl:17: :elixir_lexical.run/3\n"
    longer = COUNTER.replace("--- stderr\n", extra + "--- stderr\n")
    shorter = COUNTER.replace(
        "    (stdlib 7.3) gen_server.erl:2499: :gen_server.handle_msg/3\n", ""
    )

    assert mask(longer) == mask(COUNTER) == mask(shorter)
    assert "    <runtime frames>\nLast message" in mask(COUNTER)
    assert "    <runtime frames>\n    traces/01_counter.exs:20: (file)\n    <runtime frames>\n--- stderr" in mask(COUNTER)


def test_mask_tolerates_node_internal_frame_moves():
    moved = CART.replace("module_job:437:25", "module_job:440:7").replace("v25.9.0", "v24.11.1")
    dropped = CART.replace(
        "    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)\n", ""
    )
    node24_boom = (
        BOOM.replace("module_job:437:25", "module_job:343:25")
        .replace("loader:639:26", "loader:665:26")
        .replace("run_main:101:5", "run_main:117:5")
        .replace("v25.9.0", "v24.11.1")
        .replace(
            "    at async asyncRunEntryPointWithESMLoader",
            "    at async ModuleLoader.import (node:internal/modules/esm/loader:612:24)\n"
            "    at async asyncRunEntryPointWithESMLoader",
        )
    )

    assert mask(moved) == mask(CART) == mask(dropped)
    assert "    at traces/cart.mjs:7:1\n    <runtime frames>\n\nNode.js v_" in mask(CART)
    assert node24_boom != BOOM
    assert mask(node24_boom) == mask(BOOM)
    assert "    at traces/boom.ts:11:13\n    <runtime frames>\n\nNode.js v_" in mask(BOOM)
    assert mask(UNHANDLED.replace("v25.9.0", "v24.11.1")) == mask(UNHANDLED)


def test_mask_hides_refs_ports_and_liveview_ids():
    recaptured = (
        LIVE.replace("#PID<0.512.0>", "#PID<0.640.0>")
        .replace("phx-GOjFmOiYZVJevRSD", "phx-GOjFtvxTWuABDACB")
        .replace("#Reference<0.3104.1.20>", "#Reference<0.88.4.1>")
        .replace("#Port<0.7>", "#Port<0.12>")
    )

    assert recaptured != LIVE
    assert mask(recaptured) == mask(LIVE)
    for varying in ("0.512.0", "GOjFmOiYZVJevRSD", "0.3104.1.20", "0.7>"):
        assert varying not in mask(LIVE)
    assert '"lv:phx-_"' in mask(LIVE)
    assert '"event" => "mark"' in mask(LIVE)


def test_mask_hides_a_liveview_id_but_keeps_phx_attributes():
    masked = mask(LIVE_MARKUP)

    assert "GOjFtvxTWuABD-_8" not in masked
    assert '<div id="phx-_" data-phx-main>' in masked
    for attribute in ("phx-click", "phx-value-id", "phx-value-identifier", "phx-submit", "phx-change"):
        assert f'{attribute}="' in masked


@pytest.mark.parametrize(
    "liveview_id", ["phx-GOjFmOiYZVJevRSD", "phx-GOjFtvxTWuABD-_8", "phx-GOjFtvxTWuABD-_8xY2z"]
)
def test_mask_hides_a_liveview_id_of_any_length(liveview_id):
    masked = mask(f'<div id="{liveview_id}"> lv:{liveview_id} {liveview_id}\n')

    assert liveview_id not in masked
    assert masked == '<div id="phx-_"> lv:phx-_ phx-_'


@pytest.mark.parametrize(
    "attribute",
    [
        "phx-click",
        "phx-click-loading",
        "data-phx-main",
        "phx-value-question_1",
        'phx-value-question_1="x"',
        "phx-value-category12",
        "phx-value-user-id-42",
    ],
)
def test_mask_keeps_attribute_names_with_digits(attribute):
    markup = f"<button {attribute} phx-value-identifier>"

    assert mask(markup) == markup


def test_refusal_accepts_routes():
    assert traces.refusal(ROUTES) is None


@pytest.mark.parametrize("root", FILESYSTEM_ROOTS.values(), ids=FILESYSTEM_ROOTS.keys())
def test_refusal_refuses_each_filesystem_root(root, monkeypatch):
    monkeypatch.setenv("HOME", str(HOME))
    monkeypatch.setattr(traces, "ROOT", ROOT)
    frame = f"    (review_koans 0.1.0) {root}elixir/lib/support/db.ex:12: Support.Db.reset!/0\n"

    assert traces.refusal(COUNTER + frame) == "absolute path"


def test_course_line_change_is_stale():
    moved = COUNTER.replace("traces/01_counter.exs:12:", "traces/01_counter.exs:13:")

    assert mask(moved) != mask(COUNTER)


def test_argument_order_change_is_stale():
    swapped = COUNTER.replace(':erlang.+(1, "two")', ':erlang.+("two", 1)')

    assert mask(swapped) != mask(COUNTER)


def test_library_frames_are_not_masked():
    frame = "    (phoenix 1.8.16) lib/phoenix/router.ex:484: Phoenix.Router.__call__/5\n"
    with_library = COUNTER.replace("--- stderr\n", frame + "--- stderr\n")
    moved = with_library.replace("router.ex:484", "router.ex:485")

    assert frame in mask(with_library) + "\n"
    assert mask(moved) != mask(with_library)


def write_track(root: Path, programs: dict[str, str], fixtures: dict[str, str]) -> Path:
    traces_dir = root / "elixir" / "traces"
    traces_dir.mkdir(parents=True)
    for name, text in {**programs, **fixtures}.items():
        (traces_dir / name).write_text(text)
    return traces_dir


@pytest.fixture
def fake_runs(monkeypatch, tmp_path):
    outputs: dict[str, str] = {}
    monkeypatch.setattr(traces, "ROOT", tmp_path)
    monkeypatch.setattr(traces, "run", lambda track, program: outputs[program.name])
    return outputs


def test_capture_refuses_absolute_paths_and_warnings(fake_runs, tmp_path, capsys):
    traces_dir = write_track(
        tmp_path, {"01_clean.exs": "", "02_path.exs": "", "03_warning.exs": ""}, {}
    )
    fake_runs.update(
        {
            "01_clean.exs": COUNTER,
            "02_path.exs": COUNTER + "    (elixir 1.19.5) /tmp/elixir/lib/gen_server.ex:1: x\n",
            "03_warning.exs": "    warning: variable \"x\" is unused\n" + COUNTER,
        }
    )

    assert traces.main(["capture", "elixir"]) == 1

    assert (traces_dir / "01_clean.exs.trace").read_text() == COUNTER
    assert not (traces_dir / "02_path.exs.trace").exists()
    assert not (traces_dir / "03_warning.exs.trace").exists()
    err = capsys.readouterr().err
    assert "02_path.exs: absolute path" in err
    assert "03_warning.exs: warning:" in err


def test_capture_refuses_a_leftover_file_url(fake_runs, tmp_path):
    traces_dir = write_track(tmp_path, {"01_cart.exs": ""}, {})
    fake_runs["01_cart.exs"] = CART.replace("at traces/", "at file:///opt/elsewhere/")

    assert traces.main(["capture", "elixir", "01_cart"]) == 1
    assert not (traces_dir / "01_cart.exs.trace").exists()


def test_check_is_ok_when_masks_match(fake_runs, tmp_path, capsys):
    write_track(tmp_path, {"01_counter.exs": ""}, {"01_counter.exs.trace": COUNTER})
    fake_runs["01_counter.exs"] = COUNTER.replace("#PID<0.94.0>", "#PID<0.101.0>")

    assert traces.main(["check", "elixir"]) == 0
    assert capsys.readouterr().out == "ok\n"


def test_check_reports_stale_missing_and_orphan(fake_runs, tmp_path, capsys):
    write_track(
        tmp_path,
        {"01_counter.exs": "", "02_new.exs": ""},
        {"01_counter.exs.trace": COUNTER, "03_gone.exs.trace": COUNTER},
    )
    fake_runs["01_counter.exs"] = COUNTER.replace("01_counter.exs:12:", "01_counter.exs:13:")

    assert traces.main(["check", "elixir"]) == 1
    assert capsys.readouterr().out == (
        "stale: ['01_counter.exs']\nmissing: ['02_new.exs']\norphan: ['03_gone.exs.trace']\n"
    )


def test_unknown_track_is_refused():
    with pytest.raises(KeyError, match="unknown track"):
        traces.main(["check", "cobol"])


STDLIB_ROOTS = {
    "homebrew": "/opt/homebrew/Cellar/python@3.13/3.13.9/Frameworks/Python.framework/Versions/3.13/lib/python3.13/",
    "uv": "/work/.local/share/uv/python/cpython-3.13.9-macos-aarch64-none/lib/python3.13/",
    "debian": "/usr/lib/python3.13/",
    "free_threaded": "/opt/py/lib/python3.13t/",
}


@pytest.mark.parametrize("root", STDLIB_ROOTS.values(), ids=STDLIB_ROOTS.keys())
def test_scrub_rewrites_stdlib_paths_on_homebrew_uv_and_debian_layouts(root):
    raw = f'  File "{root}json/__init__.py", line 346, in loads\n'

    assert scrub(raw, ROOT) == '  File "<stdlib>/json/__init__.py", line 346, in loads\n'


def py_trace(dataclasses_line: int, runners_line: int) -> str:
    return (
        "exit 1\n--- stdout\n--- stderr\n"
        "Traceback (most recent call last):\n"
        '  File "traces/boom.py", line 9, in <module>\n'
        "    asyncio.run(main())\n"
        '  File "<stdlib>/asyncio/runners.py", line %d, in run\n'
        "    return runner.run(main)\n"
        "           ~~~~~~~~~~^^^^^^\n"
        '  File "<stdlib>/dataclasses.py", line %d, in __init__\n'
        "    self.x = x\n"
        '  File "traces/boom.py", line 5, in main\n'
        "    raise ValueError(x)\n"
        "ValueError: 3\n"
    ) % (runners_line, dataclasses_line)


def test_mask_tolerates_stdlib_line_moves_between_3_13_and_3_14():
    assert mask(py_trace(860, 195)) == mask(py_trace(917, 205))
    assert "  <runtime frames>\n" in mask(py_trace(860, 195)) + "\n"
    assert mask(py_trace(860, 195)).count("<runtime frames>") == 1


EXC_GROUP = (
    "exit 1\n--- stdout\n--- stderr\n"
    "  + Exception Group Traceback (most recent call last):\n"
    '  |   File "traces/group.py", line 18, in <module>\n'
    "  |     asyncio.run(charge_all(orders))\n"
    '  |   File "<stdlib>/asyncio/runners.py", line %d, in run\n'
    "  |     return runner.run(main)\n"
    "  |            ~~~~~~~~~~^^^^^^\n"
    '  |   File "<stdlib>/asyncio/base_events.py", line 719, in run_until_complete\n'
    "  |     return future.result()\n"
    "  | ExceptionGroup: unhandled errors in a TaskGroup (1 sub-exception)\n"
    "  +-+---------------- 1 ----------------\n"
    "    | Traceback (most recent call last):\n"
    '    |   File "traces/group.py", line 7, in charge\n'
    "    |     raise ValueError(order_id)\n"
    "    | ValueError: o-2\n"
    "    +------------------------------------\n"
)


def test_mask_collapses_stdlib_frames_inside_an_exception_group_gutter():
    masked = mask(EXC_GROUP % 195)

    assert masked == mask(EXC_GROUP % 205)
    assert "  |   <runtime frames>\n  | ExceptionGroup" in masked
    assert masked.count("<runtime frames>") == 1
    assert 'File "traces/group.py", line 7' in masked


def test_python_course_line_change_is_stale():
    assert mask(py_trace(860, 195).replace("line 5, in main", "line 6, in main")) != mask(
        py_trace(860, 195)
    )


def test_python_exception_change_is_stale():
    assert mask(py_trace(860, 195).replace("ValueError", "TypeError")) != mask(py_trace(860, 195))


def test_capture_refuses_python_warnings(fake_runs, tmp_path, monkeypatch):
    monkeypatch.setattr(traces.sys, "version_info", (3, 13, 9, "final", 0))
    traces_dir = tmp_path / "python" / "traces"
    traces_dir.mkdir(parents=True)
    (traces_dir / "w.py").write_text("")
    fake_runs["w.py"] = "SyntaxWarning: invalid escape\n" + py_trace(1, 2)

    assert traces.main(["capture", "python"]) == 1
    assert not (traces_dir / "w.py.trace").exists()


def test_capture_python_needs_python_3_13(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(traces, "ROOT", tmp_path)
    monkeypatch.setattr(traces.sys, "version_info", (3, 14, 0, "final", 0))
    (tmp_path / "python" / "traces").mkdir(parents=True)

    assert traces.main(["capture", "python"]) == 1
    assert (
        "capture python traces on Python 3.13: python3.13 tools/traces.py capture python"
        in capsys.readouterr().err
    )


def test_python_programs_run_with_the_current_interpreter_and_no_bytecode(monkeypatch, tmp_path):
    program = tmp_path / "python" / "traces" / "p.py"
    program.parent.mkdir(parents=True)
    program.write_text("")
    seen = {}

    def fake_subprocess(command, cwd, env, **_):
        seen.update(command=command, cwd=cwd, env=env)
        return type("Done", (), {"returncode": 0, "stdout": "", "stderr": ""})()

    monkeypatch.setattr(traces, "ROOT", tmp_path)
    monkeypatch.setattr(traces.subprocess, "run", fake_subprocess)
    traces.run("python", program)

    assert seen["command"] == [traces.sys.executable, "traces/p.py"]
    assert seen["cwd"] == program.parent.parent.resolve()
    assert seen["env"]["PYTHONDONTWRITEBYTECODE"] == "1"


def test_python_and_elixir_masks_are_unchanged():
    assert mask(COUNTER).count("    <runtime frames>") == 4
    assert mask(py_trace(860, 195)) == (
        "exit 1\n--- stdout\n--- stderr\n"
        "Traceback (most recent call last):\n"
        '  File "traces/boom.py", line 9, in <module>\n'
        "    asyncio.run(main())\n"
        "  <runtime frames>\n"
        '  File "traces/boom.py", line 5, in main\n'
        "    raise ValueError(x)\n"
        "ValueError: 3"
    )


def run_typescript(monkeypatch, tmp_path) -> tuple[Path, dict]:
    program = tmp_path / "typescript" / "traces" / "x.ts"
    program.parent.mkdir(parents=True)
    program.write_text("")
    seen = {}

    def fake_subprocess(command, cwd, env, **_):
        seen.update(command=command, cwd=cwd, env=env)
        return type("Done", (), {"returncode": 0, "stdout": "", "stderr": ""})()

    monkeypatch.setenv("NODE_OPTIONS", "--require=./elsewhere.cjs")
    monkeypatch.setattr(traces, "ROOT", tmp_path)
    monkeypatch.setattr(traces.subprocess, "run", fake_subprocess)
    traces.run("typescript", program)
    return program, seen


def test_typescript_programs_run_under_node_with_warnings_disabled(monkeypatch, tmp_path):
    program, seen = run_typescript(monkeypatch, tmp_path)

    assert seen["command"] == ["node", "--disable-warning=ExperimentalWarning", "traces/x.ts"]
    assert seen["cwd"] == program.parent.parent.resolve()
    assert {key: seen["env"][key] for key in (*traces.COLOURLESS, "NODE_DISABLE_COLORS")} == {
        **traces.COLOURLESS,
        "NODE_DISABLE_COLORS": "1",
    }
    assert "NODE_OPTIONS" not in seen["env"]


def test_scrub_rewrites_file_urls_in_node_code_frames_and_stacks():
    raw = (
        "file:///work/review-koans/typescript/traces/x.ts:4\n"
        "    at sendReceipt (file:///work/review-koans/typescript/traces/x.ts:4:11)\n"
        "    at file:///work/review-koans/typescript/traces/x.ts:9:1\n"
    )

    assert scrub(raw, ROOT) == (
        "traces/x.ts:4\n"
        "    at sendReceipt (traces/x.ts:4:11)\n"
        "    at traces/x.ts:9:1\n"
    )


def test_typescript_course_line_change_is_stale():
    moved = BOOM.replace("(traces/boom.ts:7:20)", "(traces/boom.ts:8:20)")

    assert mask(moved) != mask(BOOM)


def test_typescript_error_name_change_is_stale():
    renamed = BOOM.replace("TypeError: Cannot", "RangeError: Cannot")

    assert mask(renamed) != mask(BOOM)


def test_capture_refuses_typescript_on_another_node_major(fake_runs, tmp_path, monkeypatch, capsys):
    traces_dir = tmp_path / "typescript" / "traces"
    traces_dir.mkdir(parents=True)
    (traces_dir / "boom.ts").write_text("")
    fake_runs["boom.ts"] = BOOM

    monkeypatch.setattr(traces, "node_version", lambda: "v24.11.1")
    assert traces.main(["capture", "typescript"]) == 1
    assert not (traces_dir / "boom.ts.trace").exists()
    assert (
        "capture typescript traces on Node 25: node --version says v24.11.1"
        in capsys.readouterr().err
    )

    monkeypatch.setattr(traces, "node_version", lambda: "v25.9.0")
    assert traces.main(["capture", "typescript"]) == 0
    assert (traces_dir / "boom.ts.trace").read_text() == BOOM
