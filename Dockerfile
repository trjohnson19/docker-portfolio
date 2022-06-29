# Pull base image.
FROM ghcr.io/linuxserver/baseimage-alpine:3.15 AS base

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# System config
RUN apk --no-cache add ca-certificates wget curl && update-ca-certificates && \
    add-pkg \
		openjdk11-jre \
		gtk+3.0 \
		dbus-x11 \
		dbus \
		webkit2gtk \
		bash



FROM base as app

# ENV vars
# ARG VERSION
ENV APP_NAME=${APP_NAME:-"Portfolio Performance"}

# Download & install App into /opt then remove tar ball
## if $VERSION is not set via --build-arg -> fetch latest PP version tag_name
RUN	export VERSION=${VERSION:-$(curl --silent "https://api.github.com/repos/buchen/portfolio/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')} && \
	cd /opt && wget https://github.com/buchen/portfolio/releases/download/${VERSION}/PortfolioPerformance-${VERSION}-linux.gtk.x86_64.tar.gz && \
	tar xvzf PortfolioPerformance-${VERSION}-linux.gtk.x86_64.tar.gz && \
	rm PortfolioPerformance-${VERSION}-linux.gtk.x86_64.tar.gz

# Create the PP workspace
RUN	mkdir /opt/portfolio/workspace

# ENV vars
ARG LOCALE
ENV APP_ICON_URL=https://www.portfolio-performance.info/images/logo.png

# Configure App
## if $LOCALE is not set via --build-arg -> use en_US locale
## First, add to the beginning of the PortfolioPerformance.ini file:
### -configuration  # Set the configuration directory
### <portfolio working directory>/configuration
### -data  # Set the data directory
### <portfolio working directory>/workspace
## Then, add to the end of the configuration/config.ini file:
### osgi.nl=LOCALE  # Default = en_us
## Then, ensure 777 permissions for the /opt/portfolio folder and dependencies
## Then, install the app icon referenced above
RUN sed -i '1s;^;-configuration\n/opt/portfolio/configuration\n-data\n/opt/portfolio/workspace\n;' /opt/portfolio/PortfolioPerformance.ini && \
	echo "osgi.nl=${LOCALE:-"en_US"}" >> /opt/portfolio/configuration/config.ini && \
	chmod -R 777 /opt/portfolio && \
	install_app_icon.sh "$APP_ICON_URL"

# Copy files to container
ADD rootfs /
