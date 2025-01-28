# Getting Started

### Install Ruby v2.6.4

### Install gems

```
bundle install
```

### Setup Database

```
rake database:reset
cp config/env.rb.example config/env.rb
# edit config/env.rb to have valid options
```

### Seed Database

```
Scheduler.run(:update_location_stories_daily)
```

### Start Server

```
./bin/firefly_server
# browse to <server-ip>:8080 (Ex: http://localhost:8080/)
```
