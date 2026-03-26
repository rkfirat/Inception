.PHONY: all up down clean fclean re logs

COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
DATA_DIR := $(shell if [ -f srcs/.env ]; then awk -F= '/^DATA_DIR=/{print $$2}' srcs/.env; else echo "/home/user/data"; fi)

all: up

.env:
	@if [ ! -f srcs/.env ]; then \
		echo "Creating .env file..."; \
		cp srcs/.env.example srcs/.env; \
		echo ".env file created successfully!"; \
	fi

up: .env
	@echo "Preparing data directories: $(DATA_DIR)"
	@mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb $(DATA_DIR)/minecraft $(DATA_DIR)/portainer
	@echo "Starting containers..."
	@$(COMPOSE) up -d --build | cat

down:
	@echo "Stopping containers..."
	@$(COMPOSE) down

logs:
	@$(COMPOSE) logs -f | cat

clean:
	@echo "Removing containers and associated objects..."
	@$(COMPOSE) down -v

fclean:
	@echo "Cleaning images and data..."
	@if [ -f srcs/.env ]; then \
		DATA_DIR=$$(awk -F= '/^DATA_DIR=/{print $$2}' srcs/.env); \
		$(COMPOSE) down -v --rmi local || true; \
		sudo rm -rf $$DATA_DIR/wordpress $$DATA_DIR/mariadb $$DATA_DIR/minecraft $$DATA_DIR/portainer; \
		sudo rm -f srcs/.env; \
	else \
		echo "srcs/.env not found, performing direct cleanup..."; \
		sudo rm -rf /home/user/data/wordpress /home/user/data/mariadb /home/user/data/minecraft /home/user/data/portainer 2>/dev/null || true; \
	fi

re: fclean up
