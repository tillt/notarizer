# Notarizer

macOS notarizing frontend.

Depends on Xcode commandline tools as well as [gon](https://github.com/mitchellh/gon), a tool that allows us to poll the notarizing session status easily.

## Usage

-a ARCHIVE - tarball containing all contents for distribution
-u DEVELOPER_ACCOUNT_USER - apple developer account user name
-i APP_ID - unique application identifier
-v APP_VERSION - application version
-c CODESIGN_IDENTITY - certificate identity usable for signing code
-p PRODUCTSIGN_IDENTITY - certificate identity usable for signing installer
[-o PACKAGE_NAME] - output package name - ["package"]
[-r PROVIDER] - apple developer account team identifier - [""]
[-d DESTINATION] - installation destination folder - ["/usr/local/bin"]
[-h] - help

Example
```bash
AC_PASSWORD=XXXXX notarizer.sh \
    -a test.tar.gz \
    -u tilltoenshoff@gmail.com \
    -i org.foo.bar \
    -v 0.0.1 \
    -c "Developer ID Application: Till Toenshoff (YK4D72U3YW)" \
    -p "Developer ID Installer: Till Toenshoff (YK4D72U3YW)" \
    -r "YK4D72U3YW" \
    -o "test"
```

The first steps are quick;
- extracting the given tarball
- signing all the binaries found
- packaging
- signing the package

Then comes the notarizing step which may take minutes or even hours, be very careful with tight timeouts. During notarizing, the process will frequently poll Apple's services for a result.

The output will end with something like this;
```
[...]
2020-01-30T16:27:58.290+0100 [INFO]  notarize: notarization info: uuid=cf837823-63af-4e19-aaaf-700b711053b8 info="&{cf837823-63af-4e19-aaaf-700b711053b8 2020-01-30 15:25:26 +0000 UTC b69e187699d6d4fb23f3a4c6b0a24010ef243c7e91c2c7679cd13229c552f404 https://osxapps-ssl.itunes.apple.com/itunes-assets/Enigma113/v4/7f/b1/c4/7fb1c4ea-1ed6-108c-3ca8-8db3fc0bc63b/developer_log.json?accessKey=1580592478_3772319710354698879_k8BNI0T0xSt33Seeyf5%2BwzUTJWX18tWozLqYGt%2F9gb5fTsCOgUyyCFTzmdKRw3KCltmHb10UDLNjaC9%2FPDc0oJc7ILMJRg9uPBvMe5VTvebINlI9VC10jRpAfi4i0riw8G8GibAD0sdSxAWtM7bOOyAeoZOPvcuhj2tGWCFTINY%3D success Package Approved}"
    Status: success
2020-01-30T16:27:58.290+0100 [INFO]  downloading log file for notarization: request_uuid=cf837823-63af-4e19-aaaf-700b711053b8 url=https://osxapps-ssl.itunes.apple.com/itunes-assets/Enigma113/v4/7f/b1/c4/7fb1c4ea-1ed6-108c-3ca8-8db3fc0bc63b/developer_log.json?accessKey=1580592478_3772319710354698879_k8BNI0T0xSt33Seeyf5%2BwzUTJWX18tWozLqYGt%2F9gb5fTsCOgUyyCFTzmdKRw3KCltmHb10UDLNjaC9%2FPDc0oJc7ILMJRg9uPBvMe5VTvebINlI9VC10jRpAfi4i0riw8G8GibAD0sdSxAWtM7bOOyAeoZOPvcuhj2tGWCFTINY%3D
    File notarized!
    Stapling...
2020-01-30T16:27:59.351+0100 [INFO]  staple: executing stapler: file=/var/folders/66/mgr662nx7t90lspb7wjg8ctr0000gn/T/notarizer.e6pKWgtF/test.pkg command_path=/usr/bin/xcrun command_args=[xcrun, stapler, staple, /var/folders/66/mgr662nx7t90lspb7wjg8ctr0000gn/T/notarizer.e6pKWgtF/test.pkg]
2020-01-30T16:27:59.734+0100 [INFO]  staple: stapling complete: file=/var/folders/66/mgr662nx7t90lspb7wjg8ctr0000gn/T/notarizer.e6pKWgtF/test.pkg
    File notarized and stapled!

Notarization complete! Notarized files:
  - /var/folders/66/mgr662nx7t90lspb7wjg8ctr0000gn/T/notarizer.e6pKWgtF/test.pkg (notarized and stapled)
```

The resulting package file should now be found in the location where the script was invoked.

Example
```
-rw-r--r--  1 till staff 42518342 Jan 30 16:27 test.pkg
```

