#!/usr/bin/python

from ansible.module_utils.basic import AnsibleModule
import json
import subprocess


def run_command(command):
    """Run a shell command and return its output."""
    try:
        result = subprocess.run(
            command,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Command '{' '.join(command)}' failed: {e.stderr.strip()}")


def get_current_settings():
    """Retrieve current PIA settings."""
    output = run_command(["piactl", "-u", "dump", "daemon-settings"])
    return json.loads(output)


def apply_settings(settings):
    """Apply new settings."""
    settings_json = json.dumps(settings)
    run_command(["piactl", "-u", "applysettings", settings_json])


def main():
    module_args = {
        "settings": {"type": "dict", "required": True},
    }

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    desired_settings = module.params["settings"]

    try:
        # Retrieve current settings
        current_settings = get_current_settings()

        # Check for differences
        differences = {
            key: value
            for key, value in desired_settings.items()
            if current_settings.get(key) != value
        }

        # If there are differences, apply settings
        if differences:
            if not module.check_mode:
                current_settings.update(differences)
                apply_settings(current_settings)
            module.exit_json(changed=True, msg="PIA settings updated.", diff=differences)
        else:
            module.exit_json(changed=False, msg="PIA settings are already up-to-date.")

    except Exception as e:
        module.fail_json(msg=str(e))


if __name__ == "__main__":
    main()

