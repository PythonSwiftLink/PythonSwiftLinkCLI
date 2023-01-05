## Install PythonSwiftLinkCLI

```sh
cd <download folder>/PythonSwiftLinkCLI
chmod -x PythonSwiftLinkCLI
cp PythonSwiftLinkCLI /usr/local/bin/psl
```

## Setup Kivy-iOS:

https://kivy.org/doc/stable/guide/packaging-ios.html

if folder/project is already created then you can skip this part



## Setting up kivy-ios folder with PythonSwiftLinkCLI:

make sure your in the root path of your folder, in the terminal window


```sh
psl setup
```

```
psl project setup <project name remember -ios>
```


```sh

```

To make make everything much easier, goto **Build Phases**

click the **+** and select **New Run Script Phase**

Drag the script as far up you can (should be 3rd position now)

and paste the following inside it the code block

```
CLI=psl

for FILE in $PROJECT_DIR/wrapper_sources/*.py; do

echo $FILE; 
$CLI build $FILE "$PROJECT_DIR"/wrapper_builds

done

$CLI project update $PROJECT_DIR
```



```

```



```

```