ifndef COMMON_MK_INCLUDED
COMMON_MK_INCLUDED := 1

define print_msg
	printf "\033[33m$(1)\033[0m\n"
endef

# Wait for a key
# read:
# -n 1: wait for a character of input
# -s: Silent mode (does not show the input character on the screen).
# -r: Raw mode (disables backslash escaping).
define wait_key
	@read -n 1 -s -r -p "Press any key to continue..." key
	@echo ""  # Ensure the cursor moves to a new line
endef

# Macro to prompt the user for confirmation
define confirm_action
	read -p "$(1) [y/N] " confirm && \
	[ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]
endef


# Other shared definitions
endif # COMMON_MK_INCLUDED
