# Makefile pour Inception

COMPOSE = srcs/docker-compose.yml
DATA = /home/lumattei/data

GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m

all: build up

setup:
	@echo "$(YELLOW)Création des dossiers de données...$(NC)"
	@mkdir -p $(DATA)/mariadb
	@mkdir -p $(DATA)/wordpress
	@echo "$(GREEN)✓ Dossiers prêts$(NC)"

build:
	@echo "$(YELLOW)Construction des images...$(NC)"
	@docker compose -f $(COMPOSE) build
	@echo "$(GREEN)✓ Images construites$(NC)"

up: setup
	@echo "$(YELLOW)Démarrage des conteneurs...$(NC)"
	@docker compose -f $(COMPOSE) up -d
	@echo "$(GREEN)✓ Conteneurs lancés$(NC)"
	@echo "$(GREEN)Site accessible : https://lumattei.42.fr$(NC)"

down:
	@echo "$(YELLOW)Arrêt des conteneurs...$(NC)"
	@docker compose -f $(COMPOSE) down
	@echo "$(GREEN)✓ Conteneurs arrêtés$(NC)"

stop:
	@docker compose -f $(COMPOSE) stop

start:
	@docker compose -f $(COMPOSE) start

clean: down
	@echo "$(RED)Suppression des volumes...$(NC)"
	@docker compose -f $(COMPOSE) down -v
	@echo "$(GREEN)✓ Volumes supprimés$(NC)"

fclean: clean
	@echo "$(RED)Nettoyage complet : images et données...$(NC)"
	@docker compose -f $(COMPOSE) down -v --rmi all
	@sudo rm -rf $(DATA)/mariadb
	@sudo rm -rf $(DATA)/wordpress
	@echo "$(GREEN)✓ Tout est nettoyé$(NC)"

re: fclean all

logs:
	@docker compose -f $(COMPOSE) logs -f

ps:
	@docker compose -f $(COMPOSE) ps

.PHONY: all setup build up down stop start clean fclean re logs ps
