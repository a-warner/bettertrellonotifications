web: bundle exec thin -R config.ru start -p $PORT -e $RACK_ENV
worker: bundle exec rake jobs:work --reduce-compat
