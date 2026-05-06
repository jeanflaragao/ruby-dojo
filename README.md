# Ruby Dojo

A hands-on Ruby learning workshop focused on object-oriented programming, TDD, and design patterns. The project is structured as a multi-day dojo with exercises, demos, and specs built around an event management domain.

## Topics Covered

- ✅ **Day 1** — Ruby basics, OOP (classes, attributes, validation), and TDD with RSpec
- ✅ **Day 2** — Collections, repositories, and enumerable methods
- ✅ **Day 3** — Modules, mixins, and composable design
- ✅ **Day 4** — Error handling & contract design (Result pattern, exceptions, railway-oriented programming)
- ✅ **Day 5** — Value objects & form objects (Money, DateRange, TicketType, primitive obsession)
- ✅ **Day 6** — **Morning:** Big refactoring (project structure cleanup) | **Afternoon:** Continued development
- ✅ **Day 7** — Database integration (ActiveRecord basics, migrations, associations)
- ✅ **Day 8** — API basics (Serializers, JSON responses, versioning)
- **Day 9** — Background jobs (Sidekiq, async processing, email notifications)
- **Day 10** — Integration testing & deployment prep

**Future Topics:**

- Microservices architecture
- Docker Compose multi-service setup
- Kubernetes basics
- Message queues (RabbitMQ/Kafka)
- Service discovery & API Gateway patterns

## Project Structure

```
lib/
  models/         # ActiveRecord models (Event, Venue, Booking, TicketType)
  forms/          # Form objects for input validation
  services/       # Business logic services (BookingService, PaymentService)
  serializers/    # JSON serializers
  value_objects/  # Value objects (Money, DateRange, Address, …)
  concerns/       # Shared modules (Timestampable, Validatable)
  errors/         # Custom error classes
  api/            # Sinatra API application and controllers
spec/             # RSpec test suite
db/
  migrate/        # ActiveRecord migrations
  schema.rb       # Current database schema
config/           # Database configuration
docs/             # Day-by-day exercise prompts and summaries
demo/             # Runnable demonstration scripts
tutorial/         # Day-by-day tutorial scripts
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

| Command                   | Description                           |
| ------------------------- | ------------------------------------- |
| `make build`              | Build the Docker image                |
| `make shell`              | Start an interactive shell            |
| `make test`               | Run the full RSpec test suite         |
| `make demo`               | Run the Day 1 demo                    |
| `make demo-collections`   | Run the Day 2 collections tutorial    |
| `make demo-repository`    | Run the Day 2 repository demo         |
| `make demo-modules`       | Run the Day 3 modules tutorial        |
| `make demo-method-lookup` | Run the Day 3 method lookup demo      |
| `make demo-errors`        | Run the Day 4 error handling tutorial |
| `make demo-booking`       | Run the Day 4 booking service demo    |
| `make tutorial-day-5`     | Run the Day 5 value objects tutorial  |
| `make demo-day-5`         | Run the Day 5 demo                    |
| `make coverage`           | Open the SimpleCov coverage report    |
| `make lint`               | Run RuboCop linter                    |
| `make format`             | Auto-fix RuboCop offenses             |
| `make clean`              | Remove coverage and temp files        |

## Running Tests

```bash
make test
```

Coverage reports are generated with [SimpleCov](https://github.com/simplecov-ruby/simplecov) and saved to `coverage/index.html`.

## Tech Stack

- **Ruby** 3.3
- **RSpec** 3.13 — testing framework
- **ActiveRecord** 7.1 — ORM and migrations
- **SQLite3** — development and test database
- **Sinatra** 4.0 — lightweight web framework
- **Puma** 6 — web server
- **SimpleCov** — code coverage
- **RuboCop** + **rubocop-rspec** — linting and formatting
- **DatabaseCleaner** — test database isolation
- **Pry** — debugging
- **Docker** — containerised environment
