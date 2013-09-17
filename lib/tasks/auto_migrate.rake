namespace :db do
  namespace :auto do
    task :migrate do
      abort "Colcentric switched from auto-migrations to regular migrations.\n" +
        "There is no more `db:auto:migrate`, just `db:migrate` from now."
    end
  end
end
