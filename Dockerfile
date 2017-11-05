FROM opensuse/ruby:2.4
MAINTAINER SUSE Containers Team <containers@suse.com>

ENV COMPOSE=1
EXPOSE 3000

WORKDIR /srv/Portus
COPY Gemfile* ./

# Let's explain this RUN command:
#   1. First of all we refresh, since opensuse/ruby does a zypper clean -a in
#      the end.
#   2. Then we install dev. dependencies and the devel_basis pattern (used for
#      building stuff like nokogiri). With that we can run bundle install.
#   3. We then proceed to remove unneeded clutter: first we remove some packages
#      installed with the devel_basis pattern, and finally we zypper clean -a.
RUN zypper ref
RUN zypper -n in --no-recommends ruby2.4-devel ruby2.4-rubygem-bundler libxml2-devel nodejs libmysqlclient-devel postgresql-devel libxslt1
RUN zypper -n in --no-recommends -t pattern devel_basis
RUN bundle config --global silence_root_warning 1
RUN bundle install --retry=3
RUN zypper -n rm wicked wicked-service autoconf automake binutils bison cpp cvs flex gdbm-devel gettext-tools libtool m4 make makeinfo
RUN zypper clean -a

ADD . .