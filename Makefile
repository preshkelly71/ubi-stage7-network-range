.PHONY: lab images baseline test collect fault repair clean destroy ingest dirs

LAB_NAME := soc-a3-d81
GATEWAY  := clab-$(LAB_NAME)-gateway

dirs:
	mkdir -p evidence/reference-state pcaps

images:
	docker build -t soc-gateway:latest -f Dockerfile.gateway .
	docker build -t soc-host:latest -f Dockerfile.host .
	docker build -t soc-servers:latest -f Dockerfile.servers .
	docker build -t soc-sensor:latest -f Dockerfile.sensor .

lab: dirs images
	containerlab deploy --reconfigure --topo topology.clab.yml
	sleep 3
	$(MAKE) baseline

baseline:
	docker exec $(GATEWAY) nft -f /etc/nftables.conf

test:
	pip install --break-system-packages -q -r tests/requirements.txt 2>/dev/null || pip install -q -r tests/requirements.txt
	pytest tests/ -v --junitxml=test-results.xml

fault:
	@if [ "$(N)" = "3" ]; then \
		docker exec $(GATEWAY) tc filter del dev eth8 ingress 2>/dev/null || true; \
		docker exec $(GATEWAY) sh -c "tc qdisc del dev eth8 clsact 2>/dev/null" || true; \
		echo "fault 3 applied: dmz mirror removed"; \
	else \
		docker cp configs/gateway/baseline-faults/fault$(N)-*.conf $(GATEWAY):/tmp/fault.conf; \
		docker exec $(GATEWAY) nft -f /tmp/fault.conf; \
		echo "fault $(N) applied"; \
	fi

repair:
	@if [ "$(N)" = "3" ]; then \
		docker exec $(GATEWAY) sh -c "tc qdisc add dev eth8 clsact && tc filter add dev eth8 ingress matchall action mirred egress mirror dev eth9"; \
		echo "fault 3 repaired: dmz mirror restored"; \
	else \
		docker cp configs/gateway/nftables.conf $(GATEWAY):/tmp/repair.conf; \
		docker exec $(GATEWAY) nft -f /tmp/repair.conf; \
		echo "fault $(N) repaired"; \
	fi

collect:
	bash scripts/collect-state.sh

ingest:
	python3 scripts/ingest_adapter.py

clean:
	rm -rf evidence/reference-state test-results.xml
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

destroy:
	containerlab destroy --topo topology.clab.yml --cleanup
