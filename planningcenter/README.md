# Planning Center Export Script

## Setup

```
bundle install
```

## Usage

1. Create a Personal Access Token at https://api.planningcenteronline.com

2. Run the following command, passing in your Application ID and Secret in the named arguments:

```
export PCO_APP_ID=abcdef0123456789abcdef0123456789abcdef012345789abcdef0123456789a
export PCO_SECRET=0123456789abcdef0123456789abcdef012345789abcdef0123456789abcdef0
ruby export.rb out.csv
```

## Options

* `SKIP_INACTIVE=true`

  If you only want to export active people, you can set `SKIP_INACTIVE` like this:

  ```
  SKIP_INACTIVE=true ruby export.rb out.csv
  ```

* `NO_EMAILS_FOR_CHILDREN=true`

  For event registration, it's common for children to have their parent's email address.
  This causes issues with OneBody if they are in a separate household. If you're ok
  with children not having an email address, you can pass this option:

  ```
  NO_EMAILS_FOR_CHILDREN=true ruby export.rb out.csv
  ```
