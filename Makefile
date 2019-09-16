.PHONY: all test

all:
	docker build . -t auctionet_single_sign_on_plug

test: all
	docker run auctionet_single_sign_on_plug mix test