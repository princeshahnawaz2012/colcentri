class RenameTeamboxDatasToColcentricDatas < ActiveRecord::Migration
  def self.up
    rename_table :teambox_datas, :colcentric_datas
  end

  def self.down
    rename_table :colcentric_datas, :teambox_datas
  end
end
