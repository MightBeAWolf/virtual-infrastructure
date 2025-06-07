sudo bash << 'HEREDOC'
for script in "/tmp/provision.d"/*.sh; do
  echo "Processing $script"
  log="${script}.log"
  if ! bash "$script" "${@}" 2>&1 | tee "${script}.log"; then
    echo "Script $script failed." >&2
    echo "$script" >> /tmp/provision.d/failed.log
  fi
  rm "$script"
done
HEREDOC


