# Using xDebug with PhpStorm

Many thanks to [Oksana Cyrwus](https://github.com/oksana-c) for this solution!

## Configure IDE

### Set xDebug settings
Go to **_PhpStorm > Preferences_** (Linux shortcut: **_ctrl+alt+s_**; Mac shortcut: **_Cmd+_**, ) and check in **_Language & Frameworks / PHP / Debug_** looks like the image below

![Preferences > Languages & Frameworks > PHP > Debug](screenshots/preferences_debug.png "Preferences > Languages & Frameworks > PHP > Debug")

### Set PHP > Debug > DBGp Proxy settings
Go to **_Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy_** and follow the steps for each platform.

![Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy](screenshots/dbgp_proxy.png "Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy")

#### Mac OS

![Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy](screenshots/dbgp_proxy_macos.png "Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy")

#### Linux

Since linux users are using localhost (127.0.0.1) and xDebug has PHPSTORM as ide_key, values below can be empty with an exception of the port.

![Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy](screenshots/dbgp_proxy_linux.png "Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy")

### Update Debug Configuration

![Debug > Edit Configuration](screenshots/edit_debug_configuration.png "Debug > Edit Configuration")

### Add Remote Server
Click the plus sign, add a new "PHP Remote Debug" setting, change "Name" to `docker`, fill `IDE Key` field, and click on periods icon (highlighted green below) to add a new server.

![Remote Debug Configuration](screenshots/remote_debug_config.png "Remote Debug Configuration")

![Remote Debug Server Definition](screenshots/xdebug_server.png "Remote Debug Server Definition")

### Enable xDebug listener
Finally, click on the phone icon. If it turned green, xDebug is listening. Set some breakpoints and debug.

![Enable xDebug](screenshots/enable_xdebug.png "Enable xDebug")

## Debug

### To Debug API calls made via PostMan

Add parameter/value pair `XDEBUG_SESSION_START=PHPSTORM` to the API endpoint URL and make a call with xDebug enable in PHPSTORM.

E.g. `http://${HOSTNAME}/api/v1/product?_format=json&XDEBUG_SESSION_START=PHPSTORM`, replacing `${HOSTNAME}` with the actual hostname for your project declared in your .env file
