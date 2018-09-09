-- Number = Importance
PERM_SUPERADMIN	= 100
PERM_ADMIN		= 50
PERM_USER		= 10

sa.Ranks = {
	[PERM_SUPERADMIN] = {	-- 100
		"superadmin"
	},
	[PERM_ADMIN] = {		-- 50
		"admin"
	},
	[PERM_USER] = {			-- 10
		"user"
	}
}

sa.DefaultRank = "user"

sa.Colors = {
	servertag = Color(148, 213, 235),	-- [SAdmin] tag color for the server console.
	clienttag = Color(115, 209, 240),	-- [SAdmin] tag color for the client.
	clientcmdred = Color(220, 70, 70),	-- The red command highlight for the client.
	servercmdred = Color(255, 90, 90),	-- The red command highlight for the server.
	servercaller = Color(30, 250, 30),	-- The green highlight the caller has for the server.
	clientcaller = Color(50, 220, 50),	-- The green highlight the caller has for the client.
	targetpurple = Color(200,100,255)	-- Purple highlight to the target names.
}
