# Change Log

## [1.2.0] - unreleased
### Changed
- Existing records can now be updated based on a belongs_to foreign key
- Add Excel file format support

## [1.1.0] - 2015-08-04
### Changed
- `csv_options` config added. Thanks Maksim Burnin!

## [1.0.0] - 2015-06-09
### Changed

Major rework of the gem by new maintainer.

- Support for Mongoid
- Changed model import hooks to take 1 hash argument
- Use Rails Admin abstract model instead of ActiveRecord reflection for better compatibility with custom associations
- Support CSV and JSON
- Update styling for Bootstrap 3
- Added tests


## [0.1.9] - 2014-05-22
### Changed

- Updated/corrected README
- Merged ImportLogger work
- Merged modifications to import view
- Merged post save hook on models