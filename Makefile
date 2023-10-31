version = "v0.0.1"
name = "nvidia-cuda-pynn"
uri_target = "867279688038.dkr.ecr.us-east-1.amazonaws.com/sncr/sip/cuda:11.7.1-cudnn8-runtime-ubuntu20.04_pynn_$(version)"

build:
	docker build -t $(name) .

push:
	docker tag $(name) $(uri_target)
	docker push $(uri_target)

