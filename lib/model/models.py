import ruamel.yaml, os
from util import shell


class ContainerFactory():

    @classmethod
    def create(cls, ct_name, img, ct_path):
        ct_yml_path = f"{ct_path}/.conf/ct.yml"
        sh = shell.ShellExec()

        sh.sh(f"cd {ct_path} && mkdir -p .conf/")
        sh.sh(f"lxc init {img} {ct_name} -c security.privileged=true")
        sh.sh(f"lxc list '^{ct_name}$' --format yaml > {ct_yml_path}")

        yaml = ruamel.yaml.YAML()

        with open(ct_yml_path, 'r') as f:
            ct_obj = yaml.load(stream=f)

        with open(ct_yml_path, 'w') as f:
            yaml.dump(ct_obj[0], stream=f)

        ct = Container(ct_yml_path)
        lxtdata = {'yaml': ct_yml_path, "portforward": list()}
        setattr(ct, "lxtdata", lxtdata)

        ct.save()
        return ct


class Container():

    def __init__(self, ct_yml_path):

        yaml = ruamel.yaml.YAML()
        with open(ct_yml_path, 'r') as f:
            ct_yml_obj = yaml.load(stream=f)

        self.__dict__.update(**ct_yml_obj)


    def save(self):
        yaml = ruamel.yaml.YAML()
        yaml.register_class(Container)

        with open(self.lxtdata['yaml'], 'w') as f:
            yaml.dump(self, stream=f)


    def destroy(self):
        os.remove(self.lxtdata['yaml'])


    def current_info(self):
        current_ct_state = shell.ShellExec().cmd_out(f"lxc list '^{self.name}$' --format yaml")
        yaml = ruamel.yaml.YAML()
        return yaml.load(current_ct_state)

    def main_ip(self):
        inet =filter(lambda n:n['family']=='inet', self.current_info()[0]['state']['network']['eth0']['addresses'])
        return list(inet)[0]['address']



###class Container():
###
###
###    @classmethod
###    def  init_dump(cls, ct_json_path, name):
###       with open(ct_json_path, "w")as f:
###           json.dump({ "name": name }, f)
###
###
###    @classmethod
###    def load(cls, json_file_path):
###        with open(json_file_path) as f:
###            return json.load(f, object_hook=hook)
###
###
######class Json(object):
###
###    def __init__(self, **kwargs):
###        [setattr(self,k,v) for k,v in kwargs.items()]
###
###
###def hook(dct):
###    return Json(**dct)
