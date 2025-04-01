# oorl
A tool for opening URLs from text files. A small "script" I made for myself because I need this very often.

## Usage

### from files
```
$ oorl path1 path2 path3 ...
```

... where every argument is the path to a text file. Every URL from every file
will be opened in your default browser.

Output:

```
path1: https://example1.com
path1: https://example2.com
path2: https://another_example1.com
path2: https://another_example2.com
path3: https://yet_another_example1.com
path3: https://yet_another_example2.com
```

### last URL
```
$ oorl -l path
```

A bit specific but useful for if you want to visit the repository of the project you're in:

```
$ oorl -l .git/info
```

### from argument
```
$ oorl -s "https://example1.com       https://example2.com
           https://another_example1.com  and other things"
```

Output:

```
string: https://example1.com
string: https://example2.com
string: https://another_example1.com
```
