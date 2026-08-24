# Use phusion/passenger-ruby as base image.
# See https://github.com/phusion/passenger-docker/blob/master/CHANGELOG.md for version tags.
ARG PASSENGER_RUBY_VERSION=3.2.0
FROM phusion/passenger-ruby34:${PASSENGER_RUBY_VERSION}

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Enable Nginx and Passenger.
RUN rm -f /etc/service/nginx/down

# libvips is required by ruby-vips / Active Storage variants.
# libpq-dev and postgresql-client are required by the pg gem and dbconsole.
RUN apt-get update \
  && apt-get install --no-install-recommends -y libvips libpq-dev postgresql-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure Nginx site for the Rails app.
RUN rm -f /etc/nginx/sites-enabled/default
COPY webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Passenger's default `app` user is UID/GID 9999. In development, if ubuntu
# already occupies USER_ID (typical on Ubuntu 24.04), move ubuntu to 1001 first.
ARG USER_ID=1000
ARG ENV_ARG
RUN if [ "$ENV_ARG" = "development" ]; then \
      if [ "$(id -u ubuntu)" = "$USER_ID" ]; then \
        usermod -u 1001 ubuntu; \
        groupmod -g 1001 ubuntu; \
        find /home/ubuntu -user $USER_ID -exec chown -h 1001 {} \; ; \
        find /home/ubuntu -group $USER_ID -exec chgrp -h 1001 {} \; ; \
      fi; \
      usermod -u $USER_ID app; \
      groupmod -g $USER_ID app; \
      find /home/app -user 9999 -exec chown -h $USER_ID {} \; ; \
      find /home/app -group 9999 -exec chgrp -h $USER_ID {} \; ; \
    fi

RUN mkdir -p /home/app/webapp \
  && chown -R app:app /home/app/webapp
WORKDIR /home/app/webapp


# Install gems first so dependency changes alone invalidate this layer.
COPY --chown=app:app Gemfile Gemfile.lock ./

USER app
RUN bundle install --jobs 4 --retry 3

USER root
COPY --chown=app:app . .


EXPOSE 80
