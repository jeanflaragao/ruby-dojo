# Ruby Dojo

A hands-on Ruby learning workshop focused on object-oriented programming, TDD, and design patterns. The project is structured as a multi-day dojo with exercises, demos, and specs built around an event management domain.

## Topics Covered

- **Day 1** — Ruby basics, OOP (classes, attributes, validation), and TDD with RSpec
- **Day 2** — Collections, repositories, and enumerable methods
- **Day 3** — Modules, mixins, and composable design

## Project Structure

```
lib/          # Core Ruby classes and modules
spec/         # RSpec test suite
exercises/    # Day-by-day exercise prompts
demo/         # Runnable demonstration scripts
summary/      # Day-by-day learning summaries
```

## Prerequisites

- [Docker](https://www.docker.com/) and Docker Compose

## Getting Started

```bash
# Build the Docker image
make build

# Open an interactive shell inside the container
make shell
```

## Available Commands

| Command                 | Description                        |
| ----------------------- | ---------------------------------- |
| `make build`            | Build the Docker image             |
| `make shell`            | Start an interactive shell         |
| `make test`             | Run the full RSpec test suite      |
| `make demo`             | Run the Day 1 demo                 |
| `make demo-collections` | Run the Day 2 collections tutorial |
| `make demo-repository`  | Run the Day 2 repository demo      |
| `make coverage`         | Open the SimpleCov coverage report |
| `make lint`             | Run RuboCop linter                 |
| `make format`           | Auto-fix RuboCop offenses          |
| `make clean`            | Remove coverage and temp files     |

## Running Tests

```bash
make test
```

Coverage reports are generated with [SimpleCov](https://github.com/simplecov-ruby/simplecov) and saved to `coverage/index.html`.

## Tech Stack

- **Ruby** 3.3
- **RSpec** 3.13 — testing framework
- **SimpleCov** — code coverage
- **RuboCop** — linting and formatting
- **Pry** — debugging
- **Docker** — containerised environment
