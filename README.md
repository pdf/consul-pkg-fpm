# consul-pkg-fpm

Package generator for the official Hashicorp [Consul](https://www.consul.io/) binaries, leveraging [fpm](https://github.com/jordansissel/fpm) to generate RPM and DEB packages.  Tested on Fedora, Debian and Ubuntu.

Packages attempt to follow distribution-specific packaging decisions, so the `rpm` configuration directory is at `/etc/consul`, and the `deb` configuration directory is at `/etc/consul.d`, however the `deb` package diverges from upstream in that it runs consul as an unprivileged user, since this is far more sane IMO.  If you would prefer to have consistent configuration directories across package formats, you may use the `DEB_ETC_DIR` and `RPM_ETC_DIR` variables (see below).

## Prerequisities

Requires the following packages: `wget`; `make`; `unzip`; and `fpm`.

### deb-based distros

Install base prerequisites:

```bash
sudo apt-get install wget make unzip
```

Install fpm (or see [upstream instructions](https://github.com/jordansissel/fpm#system-packages)):

```bash
sudo apt-get install ruby ruby-dev gcc
sudo gem install fpm
```

### rpm-based distros

Install base prerequisites (you may need to substitute `dnf` for `yum` on older versions):

```bash
sudo dnf install wget make unzip
```

Install fpm (or see [upstream instructions](https://github.com/jordansissel/fpm#system-packages)):

```bash
sudo dnf install ruby ruby-devel gcc
sudo gem install fpm
```

## Building packages

To build with the defaults, simply clone the repository and run `make`:

```bash
git clone https://github.com/pdf/consul-pkg-fpm && cd $_
make
```

Packages are output to the `pkg` sub-directory, under a sub-directory per version.

Downloaded binaries and intermediary files are stored in the `.cache` sub-directory.  You can issue `make clean` or `make dist-clean` to remove cached files.

### Variables

The Makefile allows defining a few variables to allow customizing the build, they are detailed in the table below:

| Variable      | Default         | Description                                   |
|:-------------:|:---------------:|-----------------------------------------------|
| `VERSION`     | `0.9.3`         | Version of Consul to download and package     |
| `ITERATION`   | `1`             | Package version iteration - this should be increased each time a package is built |
| `ARCH`        | `amd64`         | Target architecture: `amd64`/`i386`           |
| `DEB_DIST`    | `unstable`      | Target distribution for deb-based systems     |
| `RPM_DIST`    | `fc26`          | Target distribution for rpm-based systems     |
| `DEB_ETC_DIR` | `/etc/consul.d` | Configuration directory for deb-based systems |
| `RPM_ETC_DIR` | `/etc/consul`   | Configuration directory for rpm-based systems |

Generally users are likely to only set `VERSION`, `ITERATION` and possibly `ARCH`, ie:

```bash
make VERSION=0.6.4 ITERATION=1 ARCH=amd64
```

### Targets

The Makefile defines the following targets, with `all` being the default:

| Target       | Description                                                   |
|:------------:|---------------------------------------------------------------|
| `all`        | Builds both `deb` and `rpm` packages                          |
| `deb`        | Build only the `deb` package                                  |
| `rpm`        | Build only the `rpm` package                                  |
| `clean`      | Cleans the cache and package output for the specified version |
| `distclean` | Cleans the cache and package output for all versions          |

```bash
make deb VERSION=0.6.4
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

* Andrea Bernardo Ciddio's [consul-deb](https://github.com/bcandrea/consul-deb) project for the inspiration to simplify package builds
