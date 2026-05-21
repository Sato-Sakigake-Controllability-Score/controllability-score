.PHONY: format format-check

format:
	python3 -m miss_hit_core.mh_style --fix .

format-check:
	python3 -m miss_hit_core.mh_style .
