poetry init
poetry config virtualenvs.in-project true --local
poetry env use "$(which python)"
poetry install
