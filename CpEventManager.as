funcdef void CpTimesCountChangeEvent(int);
funcdef void CpNewTimeEvent(int, int);

array<int> cpTimes(0);

interface IHandleCpEvents{
    void OnCpTimesCountChangeEvent(int);
    void OnCPNewTimeEvent(int, int);
}

class CpEventManager
{
    uint lastCount = 0;

    private array<CpTimesCountChangeEvent@> countChangeCallbacks();
    private array<CpNewTimeEvent@> newTimeCallbacks();
    
    void RegisterCallbacks(IHandleCpEvents@ iObj){
        countChangeCallbacks.InsertLast(CpTimesCountChangeEvent(iObj.OnCpTimesCountChangeEvent));
        newTimeCallbacks.InsertLast(CpNewTimeEvent(iObj.OnCPNewTimeEvent));
    }

    //TODO: fix me, only getting last cp.
    uint GetAllCpTimes(CSmPlayer@ player, array<int>@ arr){     
        if (player is null) return 0;

        auto count = uint(Math::Min(arr.Length, GetCompletedCpCount(player)));

        for (uint i = 0; i < count; i++)
        {
            arr[i] = GetCpTime(player,i);
        }

        return count;
    }
    
    const array<int>@ get_CpTimes(){
        return cpTimes;
    }

    void Update(CSmPlayer@ player){
        if (player is null) return;

        auto count = GetCompletedCpCount(player);
        if (count != lastCount)
        {
            // print(lastCount + " > " + count);
            for (uint i = 0; i < countChangeCallbacks.Length; i++)
                countChangeCallbacks[i](count - 1);
            if (count > lastCount){
                for (uint i = 0; i < newTimeCallbacks.Length; i++){
                    auto time = GetCpTime(player, count - 1);
                    newTimeCallbacks[i](count - 1, time);
                }
            }
            lastCount = count;
        }
    }

    //for debugging
    void Render(CSmPlayer@ player){
        if (player is null) return;

        UI::SetNextWindowPos(50, 200);
        UI::SetNextWindowSize(280,200);
        UI::Begin("Debug", UI::WindowFlags::NoTitleBar  | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking);
        UI::Text("has player: " + (player !is null));
        if (player !is null)
        {

            auto count = GetCompletedCpCount(player);
            UI::Text("fin count: " + count);
            
            for (uint i = 0; i < count; i++)
            {
                UI::Text( (i + 1) + " : " + Time::Format(GetCpTime(player, i)));
            }
        }

        UI::End();        
    }

    private uint GetCompletedCpCount(const CSmPlayer@ player){   
        // return 0;
        return Dev::GetOffsetUint16(player, 0x698);
    }

    private int GetCpTime(CSmPlayer@ player, const uint i){

        // return 0;
        auto CPTimesArrayPtr = Dev::GetOffsetUint64(player, 0x680);
        auto count = GetCompletedCpCount(player);

        if(i >= count) return 0;

        return Dev::ReadInt32(CPTimesArrayPtr + ((i + 1) % 100) * 0x20 + 0x1c) - player.StartTime;
    }

    
}