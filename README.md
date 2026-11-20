# Review koans

Koans that train code review. Each koan is a small ExUnit test with a blank in it. Fill the blank, run the tests, read what the footer says, and go on to the next one.

The course trains four skills:

- Spotting the real bug in plausible code.
- Defending "this is fine" when the code is fine. About one review in five is correct code.
- Predicting what code does before you run it.
- Reading a real crash trace and naming its cause.

Every exercise can fail. An unfilled blank fails, a wrong verdict fails, and a half-right fix fails.

The Elixir track has 128 koans in 9 chapters (00 to 08), from processes and mailboxes through supervision, ETS, Ecto and LiveView. The Python and TypeScript tracks follow.

`lessons/index.html` has every lesson in one page. Open it in a browser.

## Get the course

```sh
git clone https://github.com/FrankApiyo/review-koans.git
cd review-koans
```

## The Elixir track

### Setup

You need Elixir 1.19 and OTP 28, and `mix` on your path. See the [Elixir install page](https://elixir-lang.org/install.html). No version manager is required.

```sh
cd elixir
mix deps.get
```

`mix deps.get` fetches the source packages. The first `mix test` compiles them and downloads the precompiled native libraries for two of them (`exqlite` and `lazy_html`) from GitHub, so it needs a network and takes a minute or two. You need a C compiler and `make` only on a machine where no precompiled library matches.

Every run after the first compile is offline.

### The loop

Run the whole suite from `elixir/`:

```sh
mix test
```

It stops at the first koan that fails, and prints a footer that says where to work. A blank looks like this:

```
------------------------------- The master says --------------------------------
Meditate on koans/00_how_review_koans_work_test.exs:34
    Replace __ with the value that makes this true.
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

## For maintainers

`elixir/source/` is the one authored copy. The generator writes `elixir/koans/` and `elixir/solutions/` from it. The solutions build in their own folder, `elixir/_build_solutions`, so compiling them never disturbs the learner's build.

You need Python 3.13 or later and [uv](https://docs.astral.sh/uv/getting-started/installation/). Set up the harness from the repo root:

```sh
uv venv
uv pip install pytest==9.2.0
```

Then:

```sh
python tools/generate.py                  # write koans/ and solutions/ from source/
python tools/generate.py --check          # fail if they are out of date
python tools/traces.py capture elixir     # re-run the trace programs and save their output
python tools/traces.py check elixir       # fail if a saved trace is out of date
python tools/lessons.py                   # rebuild lessons/index.html
pytest tests/                             # the self-tests
```

The generator and trace tools use the Python standard library only. Run `source .venv/bin/activate` first, or call `.venv/bin/pytest`.

`REVIEW_KOANS_CHAPTER=NN pytest tests/test_elixir.py` runs the Elixir self-tests for one chapter.

## Licence

The code is under the Apache License 2.0 (see `LICENSE`). The lessons are under Creative Commons Attribution 4.0 (see `LICENSE-lessons`). See `NOTICE`.
