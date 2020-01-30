# Notarizer

macOS notarizing frontend.

Depends on Xcode commandline tools as well as [gon](https://github.com/mitchellh/gon), a tool that allows us to poll the notarizing session status easily. Wraps gon by adding steps needed for codesigning and packaging into a macOS package `pkg` installer.

## Preparation

### Application Specific Password

The password this document later on refers to is not the developer account password as entered into the developer portal. Instead it is an application specific password one can create via the [Apple account management](https://appleid.apple.com/account/manage).

### Code- and installer-signing identity

Check whether the application and installer signing certificates were properly installed and get their names;

```bash
security find-identity
```

Example
```
Policy: X.509 Basic
 Matching identities
 1) 04061D266E3097D4FEC9682C48CC1676923CA72D "Mac Developer: Till Toenshoff (359X484G5G)" (CSSMERR_TP_CERT_EXPIRED)
 2) 1CA595637509E3414FCBBC04CC70AF8A25CA3AE9 "Developer ID Application: Till Toenshoff (YK4D72U3YW)"
 3) BB89DE48FF589E465081CB0FBBECB863F8424F31 "Developer ID Installer: Till Toenshoff (YK4D72U3YW)"
 4) F55A517E699593F7CCBDBF8F2A9D78FD68ED44A5 "Apple Development: Till Toenshoff (359X484G5G)"
 4 identities found

Valid identities only
 1) 1CA595637509E3414FCBBC04CC70AF8A25CA3AE9 "Developer ID Application: Till Toenshoff (YK4D72U3YW)"
 2) BB89DE48FF589E465081CB0FBBECB863F8424F31 "Developer ID Installer: Till Toenshoff (YK4D72U3YW)"
 3) F55A517E699593F7CCBDBF8F2A9D78FD68ED44A5 "Apple Development: Till Toenshoff (359X484G5G)"
 3 valid identities found
```

### iTunes Providers

If the signing developer account is member of multiple developer teams, the provider is needed to identify the iTunes account / team. In case the below returns only one line, we won't need to specify the provider later on.

Note how we make use of an [Application Specific Password](#application-specific-password) here - make sure it is set.
```bash
xcrun iTMSTransporter -m provider -u tilltoenshoff@gmail.com -p $AC_PASSWORD
```

Example
```
Provider listing:
 - Long Name - - Short Name -
1 Mesosphere Inc. JQJDUUPXFN
2 Till Toenshoff|1054576390 YK4D72U3YW
```


## Usage

|    |                          |                                                      |
|----|--------------------------|------------------------------------------------------|
| -a | --archive                | tarball containing all contents for distribution     |
| -i | --app_id                 | unique application identifier                        |
| -v | --app_version 	        | application version                                  |
| -c | --codesign_identity      | certificate identity usable for signing code         |
| -p | --productsign_identity   | certificate identity usable for signing installer    |
| -u | --developer_account_user | apple developer account user name                    |
| -d | --destination            | installation destination folder - ["/usr/local/bin"] |
| -r | --provider               | apple developer account team identifier - [""].      |
| -o | --package_name           | output package name - ["package"]                    |
| -h | --help                   |                                                      |

Make sure you provide the [Application Specific Password](#application-specific-password) using the environment variable "AC_PASSWORD".

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

The first steps will be processed quickly;
- extracting the given tarball
- signing all the executables found
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

