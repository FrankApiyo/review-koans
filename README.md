# Review koans

Koans that train code review. Each koan is a small test with a blank in it. Fill the blank, run the tests, read what the footer says, and go on to the next one.

The course trains four skills:

- Spotting the real bug in plausible code.
- Defending "this is fine" when the code is fine. About one review in five is correct code.
- Predicting what code does before you run it.
- Reading a real crash trace and naming its cause.

Every exercise can fail. An unfilled blank fails, a wrong verdict fails, and a half-right fix fails.

The Elixir track has 128 koans in 9 chapters (00 to 08), from processes and mailboxes through supervision, ETS, Ecto and LiveView. The Python track has 69 koans in 6 chapters (00 to 05), from shared mutable state through exceptions and asyncio to money, time, files and injection. The TypeScript track has 70 koans in 6 chapters (00 to 05), from equality, numbers and sorting through references, `this`, async ordering and untrusted data to dates.

`lessons/index.html` has every lesson in one page. Open it in a browser.

## Get the course

```sh
git clone https://github.com/FrankApiyo/review-koans.git
cd review-koans
```

## The Elixir track

### Setup

You need Elixir 1.19 and OTP 28, and `mix` on your path. See the [Elixir install page](https://elixir-lang.org/install.html). The course is tested on Elixir 1.19.5 and OTP 28. If you use asdf or mise, run `asdf install` or `mise install` in the repo root: `.tool-versions` pins those versions.

```sh
cd elixir
mix deps.get
```

`mix deps.get` fetches the source packages. The first `mix test` compiles them and downloads the precompiled native libraries for two of them (`exqlite` and `lazy_html`) from GitHub, so it needs a network and takes a minute or two. You need a C compiler and `make` only on a machine where no precompiled library matches.

On a fresh machine, `mix deps.get` may ask to install Hex, and the first compile may ask to install rebar3. Answer yes to both.

Every run after the first compile is offline.

### The loop

Run the whole suite from `elixir/`:

```sh
mix test
```

It stops at the first koan that fails, and prints a footer that says where to work. A blank looks like this:

```
Replace __ with the value that makes this true.
------------------------------- The master says --------------------------------
Meditate on koans/00_how_review_koans_work_test.exs:34
    A predict koan: the blank holds the value that makes the assertion true.
0 of 128 koans answered.
```

Open the file and line after `Meditate on`, read the meditation, fill the blank, save, and run `mix test` again.

There are three kinds of koan:

- **Predict.** Replace `__` with the value that makes the assertion true.
- **Review.** Read the module in `koans/review/`. Replace the `__` in the verdict with `:fine`, or with the number of the line that holds the bug.
- **Fix.** After a bug, the next koan has you fix it in place. Hidden checks run your fix.

A wrong verdict says why:

- `Not fine: koans/review/01_ask.ex has a bug. Write the number of the line where it is.`
- `Read koans/review/01_ask.ex again: it is fine. Write :fine.`
- `Not that line. Look again at koans/review/01_ask.ex.`

A fix koan names the file to change and the koan that checks it. A failing check shows its label, never the check's input or the answer:

```
A hidden case still fails: an ordinary discount
------------------------------- The master says --------------------------------
Write:        koans/review/00_discount.ex
Exercised by: koans/00_how_review_koans_work_test.exs:42
    Fix the bug in koans/review/00_discount.ex in place. The hidden checks name what still fails.
2 of 128 koans answered.
```

Trace koans point to a real crash in `traces/`. Read it, then name its cause.

A typo in an answer is a compile error. A compile error stops the run before any koan, so no footer appears. The compiler names a `file:line`. That is your typo.

If you run one file or one koan and it passes, the footer says how many koans are answered and asks you to run the whole suite for the rest:

```
3 of 128 koans answered. Run the whole suite for the rest.
```

When every koan passes, the footer changes:

```
-------------------------------- Enlightenment ---------------------------------
All 128 koans pass. Start again with: git checkout -- koans/
```

### Starting over

```sh
git checkout -- koans/
```

This restores every blank.

### Running from Neovim

Start nvim in `elixir/`. [vim-test](https://github.com/vim-test/vim-test) runs `mix test` in the folder nvim was started in.

| vim-test       | Runs                             | In a terminal            |
| -------------- | -------------------------------- | ------------------------ |
| `:TestSuite`   | the whole suite                  | `mix test`               |
| `:TestFile`    | the file you are in              | `mix test <file>`        |
| `:TestNearest` | the single koan under the cursor | `mix test <file>:<line>` |

Put the cursor inside a koan. With the cursor above every koan, nothing runs, and the footer says:

```
No koan at that line: put the cursor inside a koan, or run the file.
```

Any other editor works too. Run the commands from a terminal.

### Do not peek

The hidden checks in `checks/` and the answers in `solutions/` are readable on disk. Don't read them before a real attempt.

If you edit or reformat a review file before you answer its verdict, its line numbers move. A wrong line then adds a note that the file has changed, and `git diff` on it shows how.

## The Python track

### Setup

You need Python 3.13 or later and [uv](https://docs.astral.sh/uv/getting-started/installation/). The course is tested on Python 3.13 and 3.14, with pytest 9.2.0. It uses no other package.

From the repo root (for example `~/review-koans`):

```sh
cd python
uv venv
uv pip install -r pyproject.toml
source .venv/bin/activate
```

Everything after the install is offline. The course blocks network access while it runs.

### The loop

Run the whole suite from `python/`:

```sh
pytest
```

It stops at the first koan that fails, and prints a footer that says where to work. A blank looks like this:

```
Replace __ with the value that makes this true.
------------------------------- The master says --------------------------------
Meditate on koans/00_how_review_koans_work_test.py:37
    A predict koan: the blank holds the value that makes the assertion true.
0 of 69 koans answered.
```

Open the file and line after `Meditate on`, read the meditation, fill the blank, save, and run `pytest` again.

There are three kinds of koan:

- **Predict.** Replace `__` with the value that makes the assertion true.
- **Review.** Read the module in `koans/review/`. Replace the `__` in the verdict with `FINE`, or with the number of the line that holds the bug.
- **Fix.** After a bug, the next koan has you fix it in place. Hidden checks run your fix.

An unanswered verdict says:

- `Replace __ with FINE, or the number of the line with the bug in koans/review/01_cart.py.`

A wrong verdict says why:

- `Not fine: koans/review/01_cart.py has a bug. Write the number of the line where it is.`
- `Read koans/review/01_cart.py again: it is fine. Write FINE.`
- `Not that line. Look again at koans/review/01_cart.py.`

A fix koan names the file to change and the koan that checks it. A failing check shows its label, never the check's input or the answer:

```
A hidden case still fails: an ordinary discount
------------------------------- The master says --------------------------------
Write:        koans/review/00_discount.py
Exercised by: koans/00_how_review_koans_work_test.py:47
    Fix the bug in koans/review/00_discount.py in place. The hidden checks name what still fails.
2 of 69 koans answered.
```

Trace koans point to a real crash in `traces/`. Read it, then name the exception and the file and line it came from.

A syntax error or a bad import in a koan file stops the run before any koan, so no footer appears. The traceback names a `file:line`. That is your typo.

A fix that loops forever never returns. Press Ctrl-C to stop the run.

If you run one file or one koan and it passes, the footer says how many koans are answered and asks you to run the whole suite for the rest:

```
3 of 69 koans answered. Run the whole suite for the rest.
```

When every koan passes, the footer changes:

```
-------------------------------- Enlightenment ---------------------------------
All 69 koans pass. Start again with: git checkout -- koans/
```

The exercise on `koans/review/05_read_upload.py` builds a file path. It is POSIX only.

Do not try the injection exercise in chapter 05 by running a shell command. Read the code and answer from the code.

### Starting over

```sh
git checkout -- koans/
```

This restores every blank.

### Running one file or one koan

```sh
pytest koans/01_shared_mutable_state_test.py
pytest koans/01_shared_mutable_state_test.py::test_lambdas_built_in_a_loop
```

### Running from Neovim

Start nvim in `python/`. [vim-test](https://github.com/vim-test/vim-test) runs `pytest` in the folder nvim was started in.

| vim-test       | Runs                             | In a terminal           |
| -------------- | -------------------------------- | ----------------------- |
| `:TestSuite`   | the whole suite                  | `pytest`                |
| `:TestFile`    | the file you are in              | `pytest <file>`         |
| `:TestNearest` | the single koan under the cursor | `pytest <file>::<test>` |

Any other editor works too. Run the commands from a terminal.

### Do not peek

The hidden checks in `checks/` and the answers in `solutions/` are readable on disk. Don't read them before a real attempt.

If you edit or reformat a review file before you answer its verdict, its line numbers move. A wrong line then adds a note that the file has changed, and `git diff` on it shows how.

## The TypeScript track

### Setup

You need Node 24 or later and npm. The course is tested on Node 24 and 25, with Vitest 4.1.12. It uses no other test package.

From the repo root (for example `~/review-koans`):

```sh
cd typescript
npm ci
```

Everything after the install is offline. The koans start no processes and open no network connections, loopback included.

### The loop

Run the whole suite from `typescript/`:

```sh
npm test
```

It stops at the first koan that fails, and prints a footer that says where to work. A blank looks like this:

```
Replace __ with the value that makes this true.
------------------------------- The master says --------------------------------
Meditate on koans/00_how_review_koans_work_test.ts:36
    A predict koan: the blank holds the value that makes the assertion true.
0 of 70 koans answered.
```

Open the file and line after `Meditate on`, read the meditation, fill the blank, save, and run `npm test` again.

There are three kinds of koan:

- **Predict.** Replace `__` with the value that makes the assertion true.
- **Review.** Read the module in `koans/review/`. Replace the `__` in the verdict with `"fine"`, or with the number of the line that holds the bug.
- **Fix.** After a bug, the next koan has you fix it in place. Hidden checks run your fix.

An unanswered verdict says:

- `Replace __ with "fine", or the number of the line with the bug in koans/review/01_cart.ts.`

A wrong verdict says why:

- `Not fine: koans/review/01_cart.ts has a bug. Write the number of the line where it is.`
- `Read koans/review/01_cart.ts again: it is fine. Write "fine".`
- `Not that line. Look again at koans/review/01_cart.ts.`

A fix koan names the file to change and the koan that checks it. A failing check shows its label, never the check's input or the answer:

```
A hidden case still fails: an ordinary discount
------------------------------- The master says --------------------------------
Write:        koans/review/00_discount.ts
Exercised by: koans/00_how_review_koans_work_test.ts:44
    Fix the bug in koans/review/00_discount.ts in place. The hidden checks name what still fails.
2 of 70 koans answered.
```

Trace koans point to a real crash in `traces/`. Read it, then name the error and the file and line it came from.

A syntax error or a bad import in a koan file stops the run before any koan. The footer names the file and the error. That is your typo.

A fix that never returns, such as a loop or a promise chain that never stops, needs Ctrl-C to stop the run.

If you run one file or one koan and it passes, the footer says how many koans are answered and asks you to run the whole suite for the rest:

```
3 of 70 koans answered. Run the whole suite for the rest.
```

When every koan passes, the footer changes:

```
-------------------------------- Enlightenment ---------------------------------
All 70 koans pass. Start again with: git checkout -- koans/
```

### Starting over

```sh
git checkout -- koans/
```

This restores every blank.

### Running one file or one koan

```sh
npx vitest run koans/<file>
npx vitest run koans/<file>:<line>
```

`<file>` is a name such as `01_equality_numbers_and_sorting_test.ts`. `<line>` is the line of the koan's `test(` call, and only that koan runs. The line after `Meditate on` in the footer is the blank, not the `test(` line, which is usually one line above it.

### Running from Neovim

Start nvim in `typescript/`. [vim-test](https://github.com/vim-test/vim-test) runs Vitest in the folder nvim was started in.

| vim-test       | Runs                             | In a terminal                    |
| -------------- | -------------------------------- | -------------------------------- |
| `:TestSuite`   | the whole suite                  | `npm test`                       |
| `:TestFile`    | the file you are in              | `npx vitest run <file>`          |
| `:TestNearest` | the single koan under the cursor | `npx vitest run <file>:<line>`   |

Any other editor works too. Run the commands from a terminal.

### Do not peek

The hidden checks in `checks/` and the answers in `solutions/` are readable on disk. Don't read them before a real attempt.

If you edit or reformat a review file before you answer its verdict, its line numbers move. A wrong line then adds a note that the file has changed, and `git diff` on it shows how.

## For maintainers

`elixir/source/` is the one authored copy. The generator writes `elixir/koans/` and `elixir/solutions/` from it. The solutions build in their own folder, `elixir/_build_solutions`, so compiling them never disturbs the learner's build.

You need Python 3.13 or later and [uv](https://docs.astral.sh/uv/getting-started/installation/). Set up the harness from the repo root:

```sh
uv venv
uv pip install pytest==9.2.0
```

Then:

```sh
.venv/bin/python tools/generate.py                  # write koans/ and solutions/ from source/
.venv/bin/python tools/generate.py --check          # fail if they are out of date
.venv/bin/python tools/traces.py capture elixir     # re-run the trace programs and save their output
.venv/bin/python tools/traces.py check elixir       # fail if a saved trace is out of date
python3.13 tools/traces.py capture python           # re-run the Python trace programs and save their output
.venv/bin/python tools/traces.py capture typescript # re-run the TypeScript trace programs (needs Node 25)
.venv/bin/python tools/lessons.py                   # rebuild lessons/index.html
.venv/bin/pytest tests/                             # the self-tests
```

The generator and trace tools use the Python standard library only. The commands call the venv directly, so no activation is needed.

`REVIEW_KOANS_CHAPTER=NN .venv/bin/pytest tests/test_elixir.py` runs the Elixir self-tests for one chapter.

`REVIEW_KOANS_CHAPTER=NN .venv/bin/pytest tests/test_python.py` does the same for the Python track.

`REVIEW_KOANS_CHAPTER=NN .venv/bin/pytest tests/test_typescript.py` does the same for the TypeScript track.

## Licence

The code is under the Apache License 2.0 (see `LICENSE`). The lessons are under Creative Commons Attribution 4.0 (see `LICENSE-lessons`). The lessons are the lesson text at the top of each chapter file and `lessons/index.html`; everything else is under Apache 2.0. See `NOTICE`.
