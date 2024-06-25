use Config;use File::Spec;use Cwd;print join$main::Config{'path_sep'},grep{!$seen{$_}++}map{'File::Spec'->file_name_is_absolute($_)&&-d?Cwd::realpath$_:'File::Spec'->canonpath($_)}'File::Spec'->path;
