# OneBody Import Script

This is a very simple script you can use to automate syncing of data with OneBody.

NOTE: Your version of OneBody must be 3.5.0 or higher for this to work.

## Setup

```
bundle install
```

Then, edit the `USER_EMAIL`, `USER_KEY`, and `URL` constants at the top of the import.rb file. To get your `USER_KEY`,
you'll need to set a 50-character key on your OneBody Person record like this:

```
ssh server
onebody run rails console
p = Person.find(1) # your id goes here
p.api_key = SecureRandom.hex(25) # 25 hex digits equals 50 characters
p.save
```

## Usage

Run the script:

```
ruby import.rb path/to/data.csv
```

Make sure your CSV has headings that EXACTLY match the attributes that OneBody expects.
To see a list of those attributes, start a CSV import from the UI and take note of the
attributes available for matching there.

It is highly recommended you use the `legacy_id` and `legacy_family_id` columns for matching.
Doing this will ensure records are always matched properly and make your life much simpler.
