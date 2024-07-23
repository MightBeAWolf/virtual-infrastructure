from typing import List, Tuple

def filter_keys_of_subitems(old_dict, keep=None, remove=None, rename: List[str]=None ):
    result = {}
    rename_mappings = [m.split(':') for m in rename or []]
    for key, old_subitem in old_dict.items():
        subresult = {}
        for sub_key, sub_value in old_subitem.items():
            new_key = next((new for original,new in rename_mappings if sub_key == original), None)
            if new_key:
                subresult[new_key] = sub_value
            elif (True if keep is None else sub_key in keep) \
            and (True if remove is None else sub_key not in remove):
                subresult[sub_key] = sub_value
        result[key] = subresult
    return result

def flatten_to_subitem(old_dict, *subkeys):
    result = {}
    for key, old_subitem in old_dict.items():
        result[key] = {}
        for subkey in subkeys:
            result[key].update(old_subitem[subkey])
    return result

def join_dicts_by_key(*original_dicts):
    result = {}
    for d in original_dicts:
        for key, value in d.items():
            if key in result:
                if isinstance(result[key], dict) and isinstance(value, dict):
                    result[key].update(value)
                elif isinstance(result[key], list) and isinstance(value, list):
                    result[key].extend(value)
                elif isinstance(result[key], set) and isinstance(value, set):
                    result[key].update(value)
                else:
                    result[key] = value
            else:
                result[key] = value
    return result

def this_item(arg):
    return arg


class FilterModule(object):
    def filters(self):
        return {
            'filter_keys_of_subitems': filter_keys_of_subitems,
            'flatten_to_subitem': flatten_to_subitem,
            'join_dicts_by_key': join_dicts_by_key,
            'this_item': this_item,
        }

