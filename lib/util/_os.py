from util import shell

class OS():

    @classmethod
    def default_if(cls):
        sh = shell.ShellExec()
        return sh.cmd_out("route | awk '{if($1 == \"default\") print $8;}'")
