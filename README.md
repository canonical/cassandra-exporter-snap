# Cassandra Exporter Snap

[![Pull Request](https://github.com/canonical/cassandra-exporter-snap/actions/workflows/pull-request.yaml/badge.svg)](https://github.com/canonical/cassandra-exporter-snap/actions/workflows/pull-request.yaml)
[![Release Snap](https://github.com/canonical/cassandra-exporter-snap/actions/workflows/release.yaml/badge.svg)](https://github.com/canonical/cassandra-exporter-snap/actions/workflows/release.yaml)

A snap package for [Prometheus Cassandra Exporter](https://github.com/criteo/cassandra_exporter).

## Overview

The Cassandra Exporter connects to Cassandra's JMX port on each node and exports
metrics as Prometheus metrics. It must run on every Cassandra node.

> **Note**: This exporter only works with Cassandra 3.x. For Cassandra 4.x, consider
> using the [official Prometheus endpoint](https://cassandra.apache.org/doc/latest/cassandra/operating/metrics.html)
> built into Cassandra 4.0+.

### Default Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 8080 | TCP | Prometheus metrics endpoint |
| 7199 | TCP | Cassandra JMX (target, not opened by snap) |

## Installation

```bash
sudo snap install cassandra-exporter
```

## Usage

### Running as a Service (Daemon)

```bash
sudo snap start --enable cassandra-exporter
sudo snap stop cassandra-exporter
```

## Configuration

### Connection

```bash
# Set the Cassandra JMX host:port (default: localhost:7199)
sudo snap set cassandra-exporter cassandra.host=localhost:7199

# Set JMX credentials if authentication is enabled
sudo snap set cassandra-exporter cassandra.user=jmxuser
sudo snap set cassandra-exporter cassandra.password=jmxpassword

# Change the metrics endpoint port (default: 8080)
sudo snap set cassandra-exporter web.listen-port=9500

sudo snap restart cassandra-exporter
```

### Config File

The exporter config file is stored at `$SNAP_COMMON/config.yml` (typically `/var/snap/cassandra-exporter/common/config.yml`).
Edit this file directly to configure metric blacklists and scrape frequencies.

```bash
sudo nano /var/snap/cassandra-exporter/common/config.yml
sudo snap restart cassandra-exporter
```

To view current snap configuration:

```bash
sudo snap get cassandra-exporter
```

## Development

This snap follows the [Canonical Observability snaps blueprint](https://github.com/canonical/observability/tree/main/blueprints/snaps).

### Prerequisites

- `snapcraft`
- `just`
- `yq`
- `gh` (GitHub CLI)

### Common Commands

```bash
# Build the snap locally
just pack

# Run tests
just test

# Update to latest upstream version
just update criteo/cassandra_exporter

# Fetch latest centralized files from canonical/observability
just refresh
```

## License

Apache License 2.0
