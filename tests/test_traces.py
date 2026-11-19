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

LIVE = """\
[error] GenServer #PID<0.512.0> terminating
** (FunctionClauseError) no function clause matching in Board.handle_event/3
Last message: %Phoenix.Socket.Message{topic: "lv:phx-GHk3x_9-aQ", event: "event", \
payload: %{"event" => "mark"}, ref: "4", join_ref: "1"}
State: %{id: "phx-GHk3x_9-aQ", monitor: #Reference<0.3104.1.20>, port: #Port<0.7>}
"""


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

    assert mask(moved) == mask(CART) == mask(dropped)
    assert "    at traces/cart.mjs:7:1\n    <runtime frames>\n\nNode.js v_" in mask(CART)


def test_mask_hides_refs_ports_and_liveview_ids():
    recaptured = (
        LIVE.replace("#PID<0.512.0>", "#PID<0.640.0>")
        .replace("phx-GHk3x_9-aQ", "phx-F0zQ-r_2Lm")
        .replace("#Reference<0.3104.1.20>", "#Reference<0.88.4.1>")
        .replace("#Port<0.7>", "#Port<0.12>")
    )

    assert recaptured != LIVE
    assert mask(recaptured) == mask(LIVE)
    for varying in ("0.512.0", "GHk3x", "0.3104.1.20", "0.7>"):
        assert varying not in mask(LIVE)
    assert '"lv:phx-_"' in mask(LIVE)
    assert '"event" => "mark"' in mask(LIVE)


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
            "02_path.exs": COUNTER + "    (elixir 1.19.5) /opt/elixir/lib/gen_server.ex:1: x\n",
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
