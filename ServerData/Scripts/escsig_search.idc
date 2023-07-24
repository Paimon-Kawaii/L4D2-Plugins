/* IDA script to search for a binary pattern in SourceMod's gamedata format.
 * by Peace-Maker
 */

#include <idc.idc>

static main()
{
  auto signature = AskStr("", "Type the escaped signature you want to search for like \\xA1\\x8B\\xC1 etc.\n\\2A is the wildcard character which gets replaced with \"?\"\n");
  signature = trim(signature);
  
  if(signature == "")
  {
    Message("** No signature entered! Aborted **");
    return;
  }
  
  auto pos = -1;
  
  do
  {
    pos = strstr(signature, "\x");
    if(pos != -1)
    {
      if(substr(signature, pos+1, pos+3) == "2A" || substr(signature, pos+1, pos+3) == "2a")
      {
        signature = sprintf("%s ?%s", substr(signature, 0, pos-1), substr(signature, pos+3, -1));
      }
      else
      {
        signature = sprintf("%s %s", substr(signature, 0, pos-1), substr(signature, pos+1, -1));
      }
    }
  }
  while(pos != -1);
  
  signature = trim(signature);
  Message("Searching for: %s\n",signature);
  
  auto addr;
  addr = FindBinary(addr, SEARCH_DOWN|SEARCH_NEXT, signature);
  if(addr == BADADDR)
  {
    Message("** NOT FOUND - Bad signature. **\n");
  }
  else
  {
    Jump(addr);
    auto count = IsGoodSig(signature);
    if(count == 1)
    {
      Message("Single match at %a\n", addr);
    }
    else
    {
      Message("CAUTION: There are multiple matches. First match of total %d at %a\n", count, addr);
    }
  }
}

// From asherkin's makesig.idc
static IsGoodSig(sig)
{
	auto count, addr;
	addr = FindBinary(addr, SEARCH_DOWN|SEARCH_NEXT, sig);
	while (addr != BADADDR)
	{
		count = count + 1;
		addr = FindBinary(addr, SEARCH_DOWN|SEARCH_NEXT, sig);
	}
	return count;
}