FROM zekiunal/portus

COPY Gemfile* ./

# Let's explain this RUN command:
#   1. First of all we refresh, since opensuse/ruby does a zypper clean -a in
#      the end.
#   2. Then we install dev. dependencies and the devel_basis pattern (used for
#      building stuff like nokogiri). With that we can run bundle install.
#   3. We then proceed to remove unneeded clutter: first we remove some packages
#      installed with the devel_basis pattern, and finally we zypper clean -a.
RUN    gem install bundler --no-ri --no-rdoc -v 1.16.0
RUN    update-alternatives --install /usr/bin/bundle bundle /usr/bin/bundle.ruby2.5 3
RUN    update-alternatives --install /usr/bin/bundler bundler /usr/bin/bundler.ruby2.5 3
RUN    bundle install --retry=3
RUN    zypper -n rm wicked wicked-service autoconf automake binutils bison cpp cvs flex gdbm-devel gettext-tools libtool m4 make makeinfo
RUN    zypper clean -a

ADD . .