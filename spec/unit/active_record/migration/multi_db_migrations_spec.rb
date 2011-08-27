require 'spec/spec_helper'

class SpecMigration < ActiveRecord::Migration
  def self.up
    execute "UPDATE log_records SET level = 'debug'"
  end

  def self.down
    execute "UPDATE log_records SET level = 'blah'"
  end
end

class SpecMultiDbMigration < ActiveRecord::Migration
  db_magic :connection => :logs

  def self.up
    execute "UPDATE log_records SET level = 'debug'"
  end

  def self.down
    execute "UPDATE log_records SET level = 'blah'"
  end
end

class SpecMultiDbMigration2 < ActiveRecord::Migration
  def self.up
    execute "UPDATE log_records SET level = 'yo'"
    on_db(:logs) { execute "UPDATE log_records SET level = 'debug'" }
  end

  def self.down
    execute "UPDATE log_records SET level = 'bar'"
    on_db(:logs) { execute "UPDATE log_records SET level = 'blah'" }
  end
end

class SpecMultiDbMigration3 < ActiveRecord::Migration
  db_magic :connection => [:logs, :default]

  def self.up
    execute "UPDATE log_records SET level = 'hoho'"
  end

  def self.down
    execute "UPDATE log_records SET level = 'blah'"
  end
end

class SpecMultiDbMigration4 < ActiveRecord::Migration
  db_magic :connections => [:logs, :default]

  def self.up
    execute "UPDATE log_records SET level = 'hoho'"
  end

  def self.down
    execute "UPDATE log_records SET level = 'blah'"
  end
end

describe "Multi-db migractions" do
  before(:all) do
    DbCharmer.connections_should_exist = true
  end

  after(:all) do
    DbCharmer.connections_should_exist = false
  end

  describe "w/o any magic calls" do
    it "should send all up requests to the default connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'debug'")
      SpecMigration.migrate(:up)
    end

    it "should send all down requests to the default connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'blah'")
      SpecMigration.migrate(:down)
    end

    describe "after AR::Migration db_magic call" do
      it "should use default migration config" do
        ActiveRecord::Migration.db_magic :connection => :logs
        ActiveRecord::Base.connection.should_not_receive(:execute)
        DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'debug'")
        SpecMigration.migrate(:up)
        ActiveRecord::Migration.db_magic :connection => :default
      end
    end
  end

  describe "with db_magic calls" do
    it "should send all up requests to specified connection" do
      ActiveRecord::Base.connection.should_not_receive(:execute)
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'debug'")
      SpecMultiDbMigration.migrate(:up)
    end

    it "should send all down requests to specified connection" do
      ActiveRecord::Base.connection.should_not_receive(:execute)
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'blah'")
      SpecMultiDbMigration.migrate(:down)
    end

    describe "after AR::Migration db_magic call" do
      it "should use spcified connection and ignore global migration config" do
        ActiveRecord::Migration.db_magic :connection => :slave01
        ActiveRecord::Base.connection.should_not_receive(:execute)
        DbCharmer::ConnectionFactory.connect(:slave01).should_not_receive(:execute)
        DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'debug'")
        SpecMultiDbMigration.migrate(:up)
        ActiveRecord::Migration.db_magic :connection => :default
      end
    end
  end

  describe "with on_db blocks" do
    it "should send specified up requests to specified connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'yo'")
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'debug'")
      SpecMultiDbMigration2.migrate(:up)
    end

    it "should send secified down requests to specified connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'bar'")
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'blah'")
      SpecMultiDbMigration2.migrate(:down)
    end
  end

  describe "with db_magic calls" do
    it "should send all up requests to specified connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'hoho'")
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'hoho'")
      SpecMultiDbMigration3.migrate(:up)
    end

    it "should send all down requests to specified connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'blah'")
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'blah'")
      SpecMultiDbMigration3.migrate(:down)
    end
  end

  describe "with db_magic calls" do
    it "should send all up requests to specified connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'hoho'")
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'hoho'")
      SpecMultiDbMigration4.migrate(:up)
    end

    it "should send all down requests to specified connection" do
      ActiveRecord::Base.connection.should_receive(:execute).with("UPDATE log_records SET level = 'blah'")
      DbCharmer::ConnectionFactory.connect(:logs).should_receive(:execute).with("UPDATE log_records SET level = 'blah'")
      SpecMultiDbMigration4.migrate(:down)
    end
  end
end
