#!/bin/bash
if [ "${CIRCLE_BRANCH}" == "master" ]
then
  export RUN_SAUCE_TESTS=true
fi

bundle exec rake db:create db:migrate db:seed
bundle exec rspec
exit 0
