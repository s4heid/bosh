BOSH_REPO_SRC = File.expand_path(File.join('..', '..', '..'), __FILE__)

BOSH_DIRECTOR_ROOT = File.join(BOSH_REPO_SRC, 'bosh-director')
BOSH_DEV_ROOT = File.join(BOSH_REPO_SRC, 'bosh-dev')

$LOAD_PATH << File.join(BOSH_DIRECTOR_ROOT, 'lib')
$LOAD_PATH << File.join(BOSH_DEV_ROOT, 'lib')

require 'rspec'
require 'sequel'
require 'logging'
require 'securerandom'

require 'bosh/director/config'

require 'db_migrator'

require 'bosh/dev/db/db_helper'

module DBSpecHelper
  class << self
    attr_reader :db, :director_migrations_dir, :director_migrations_digest_file

    def init
      @director_migrations_dir = File.join(BOSH_DIRECTOR_ROOT, 'db', 'migrations', 'director')
      @director_migrations_digest_file  = File.join(BOSH_DIRECTOR_ROOT, 'db',  'migrations', 'migration_digests.json')
    end

    def connect_database
      init_logger = Logging::Logger.new('TestLogger')

      db_options = {
        type: ENV.fetch('DB', 'sqlite'),
        name: "#{SecureRandom.uuid.delete('-')}_director",
        username: ENV['DB_USER'],
        password: ENV['DB_PASSWORD'],
        host: ENV['DB_HOST'],
        port: ENV['DB_PORT'],
      }

      @db_helper =
        Bosh::Dev::DB::DBHelper.build(db_options: db_options)


      @db_helper.create_db

      Sequel.default_timezone = :utc
      @db = Sequel.connect(@db_helper.connection_string, max_connections: 32, pool_timeout: 10)
    end

    def disconnect_database
      if @db
        @db.disconnect
        @db_helper.drop_db

        @db = nil
        @db_helper = nil
      end
    end

    def reset_database
      disconnect_database
      connect_database
    end

    def migrate_all_before(migration_file)
      reset_database
      version = migration_file.split('_').first.to_i
      migrate_to_version(version - 1)
    end

    def migrate(migration_file)
      version = migration_file.split('_').first.to_i
      migrate_to_version(version)
    end

    def get_latest_migration_script
      Dir.entries(@director_migrations_dir).select {|f| !File.directory? f}.sort.last
    end

    def get_migrations
      Dir.glob(File.join(@director_migrations_dir, '..', '**', '[0-9]*_*.rb'))
    end

    def skip_on_mysql(example, why = nil)
      skip_on_db_type(:mysql, example, why)
    end

    def skip_on_postgresql(example, why = nil)
      skip_on_db_type(:postgresql, example, why)
    end

    def skip_on_sqlite(example, why = nil)
      skip_on_db_type(:sqlite, example, why)
    end

    private

    def skip_on_db_type(db_type, example, why)
      if db_is?(db_type)
        message = "Assertion not supported on DB #{db_type.inspect}"
        message += " because '#{why}'." if why
        example.skip(message)
      end
    end

    def db_is?(db_type)
      /#{db_type}/.match?("#{db.adapter_scheme}")
    end

    def migrate_to_version(version)
      DBMigrator.new(@db, target: version).migrate
    end
  end
end

DBSpecHelper.init

RSpec.configure do |rspec|
  rspec.after(:suite) do
    DBSpecHelper.disconnect_database
  end
end
