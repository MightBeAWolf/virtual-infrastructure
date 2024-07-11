
def filter_keys_of_subitems(old_dict, keep=None, remove=None):
    result = {}
    for key, old_subitem in old_dict.items():
        result[key] = {k: v for k, v in old_subitem.items()
                       if (True if keep is None else k in keep) and
                          (True if remove is None else k not in remove)}
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

