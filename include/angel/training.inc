methodmap Training < Dynamic
{
    public Training()
    {
        return view_as<Training>(Dynamic());
    }

    property bool IsLateLoad
    {
        public get()
        {
            return this.GetBool("IsLateLoad");
        }
        public set(bool late)
        {
            this.SetBool("IsLateLoad", late);
        }
    }
    property int SICountLimit
    {
        public get()
        {
            return FindConVar("angel_infected_limit").IntValue;
        }
    }
    property int OffsetAmmo
    {
        public get()
        {
            return FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
        }
    }
    property ArrayList SelfSaveArray
    {
        public get()
        {
            return view_as<ArrayList>(this.GetHandle("SelfSaveArray"));
        }
        public set(ArrayList array)
        {
            this.SetHandle("SelfSaveArray", view_as<Handle>(array));
        }
    }
    property ArrayList SaveMsgArray
    {
        public get()
        {
            return view_as<ArrayList>(this.GetHandle("SaveMsgArray"));
        }
        public set(ArrayList array)
        {
            this.SetHandle("SaveMsgArray", view_as<Handle>(array));
        }
    }
    property StringMap WeaponOffsets
    {
        public get()
        {
            return view_as<StringMap>(this.GetHandle("WeaponOffsets"));
        }
        public set(StringMap map)
        {
            this.SetHandle("WeaponOffsets", view_as<Handle>(map));
        }
    }
    property ConVar HealthConVar
    {
        public get()
        {
            return view_as<ConVar>(this.GetHandle("HealthConVar"));
        }
        public set(ConVar convar)
        {
            this.SetHandle("HealthConVar", view_as<Handle>(convar));
        }
    }
    property ConVar TrainConVar
    {
        public get()
        {
            return view_as<ConVar>(this.GetHandle("TrainConVar"));
        }
        public set(ConVar convar)
        {
            this.SetHandle("TrainConVar", view_as<Handle>(convar));
        }
    }
    property ConVar ShotConVar
    {
        public get()
        {
            return view_as<ConVar>(this.GetHandle("ShotConVar"));
        }
        public set(ConVar convar)
        {
            this.SetHandle("ShotConVar", view_as<Handle>(convar));
        }
    }
    property ConVar RefillConVar
    {
        public get()
        {
            return view_as<ConVar>(this.GetHandle("RefillConVar"));
        }
        public set(ConVar convar)
        {
            this.SetHandle("RefillConVar", view_as<Handle>(convar));
        }
    }
    public void Init()
    {
        this.SelfSaveArray = new ArrayList();
        this.SaveMsgArray = new ArrayList();
        this.WeaponOffsets = new StringMap();
        this.WeaponOffsets.SetValue("weapon_smg", 20);
        this.WeaponOffsets.SetValue("weapon_sniper_awp", 40);
        this.WeaponOffsets.SetValue("weapon_pumpshotgun", 28);
        this.WeaponOffsets.SetValue("weapon_smg_silenced", 20);
        this.WeaponOffsets.SetValue("weapon_shotgun_chrome", 28);
        for(int i = 0; i <= MaxClients; i++)
        {
            this.SelfSaveArray.Push(0);
            this.SaveMsgArray.Push(false);
        }
    }
    public int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
    {
        static char sWeapon[32];
        GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));

        int offset;
        this.WeaponOffsets.GetValue(sWeapon, offset);

        if( offset )
        {
            if( iAmmo != -1 ) SetEntData(client, this.OffsetAmmo + offset, iAmmo);
            else return GetEntData(client, this.OffsetAmmo + offset);
        }

        return 0;
    }
};