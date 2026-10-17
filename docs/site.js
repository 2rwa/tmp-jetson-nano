(() => {
"use strict";
const api="https://api.github.com/repos/2rwa/tmp-jetson-nano";
const byId=(id)=>document.getElementById(id);
const set=(id,value)=>{byId(id).textContent=value;};
const labels={success:"成功",failure:"失敗",cancelled:"中止",skipped:"スキップ",in_progress:"実行中",queued:"待機中",pending:"待機中",completed:"完了",timed_out:"タイムアウト"};
const label=(value)=>labels[value]||value||"未確認";
const date=(s)=>s?new Date(s).toLocaleString("ja-JP",{timeZone:"Asia/Tokyo",month:"2-digit",day:"2-digit",hour:"2-digit",minute:"2-digit"}):"—";
const size=(n)=>(n/1073741824).toFixed(2)+" GiB";
function makeLink(url,title){const a=document.createElement("a");a.href=url;a.textContent=title;a.target="_blank";a.rel="noopener noreferrer";return a;}
async function request(url){const response=await fetch(url,{headers:{Accept:"application/vnd.github+json"},cache:"no-store"});if(!response.ok)throw new Error("HTTP "+response.status);return response.json();}
function steps(items){
  const list=byId("build-steps");list.replaceChildren();
  for(const step of items.filter(s=>!s.name.startsWith("Post ")&&!["Set up job","Complete job"].includes(s.name))){
    const li=document.createElement("li");li.textContent=step.name+" — "+label(step.conclusion||step.status);
    li.className=step.conclusion==="success"?"done":step.conclusion==="failure"?"error":step.status==="in_progress"?"active":"";
    list.appendChild(li);
  }
}
function history(runs){
  const el=byId("recent-runs");el.replaceChildren();
  if(!runs.length){el.textContent="まだビルド実行履歴がありません";return;}
  for(const run of runs){
    const a=makeLink(run.html_url,"");
    const n=document.createElement("span");n.textContent="#"+run.run_number;
    const s=document.createElement("span");s.textContent=label(run.conclusion||run.status)+" / "+(run.display_title||run.name);s.className=run.conclusion==="success"?"state-ok":run.conclusion?"state-bad":"";
    const t=document.createElement("time");t.textContent=date(run.created_at);a.append(n,s,t);el.appendChild(a);
  }
}
function releases(list){
  const el=byId("release-list");el.replaceChildren();
  if(!list.length){el.textContent="公開済みのイメージはありません。ビルド完了後に掲載されます。";return;}
  for(const release of list.slice(0,5)){
    const asset=(release.assets||[]).find(a=>a.name.endsWith(".img.xz"));
    const item=document.createElement("div");item.className="release";
    const desc=document.createElement("div");
    const h=document.createElement("h3");h.textContent=release.name||release.tag_name;
    const p=document.createElement("p");p.textContent=(release.prerelease?"Experimental · ":"")+date(release.published_at||release.created_at)+(asset?" · "+asset.name+" · "+size(asset.size):" · イメージ未添付");
    desc.append(h,p);item.append(desc,makeLink(asset?asset.browser_download_url:release.html_url,asset?"ダウンロード ↗":"詳細 ↗"));el.appendChild(item);
  }
}
let busy=false;
async function refresh(){
  if(busy||document.hidden)return;busy=true;byId("refresh").disabled=true;
  const [r1,r2]=await Promise.allSettled([request(api+"/actions/workflows/build.yml/runs?per_page=8"),request(api+"/releases?per_page=8")]);
  try{
    if(r1.status==="fulfilled"){
      const runs=r1.value.workflow_runs||[];history(runs);
      if(runs.length){
        const last=runs[0];set("latest-state",label(last.conclusion||last.status));
        set("latest-title",last.display_title||last.name||"Ubuntu 24.04");set("latest-run","#"+last.run_number);
        set("latest-date",date(last.run_started_at||last.created_at));byId("latest-link").href=last.html_url;
        try{
          const response=await request(api+"/actions/runs/"+last.id+"/jobs?per_page=20");
          const job=(response.jobs||[])[0];
          if(job){
            const current=(job.steps||[]).find(s=>s.status==="in_progress");
            const failed=(job.steps||[]).find(s=>s.conclusion==="failure");
            set("latest-step",current?current.name:failed?failed.name:label(job.conclusion||job.status));
            steps(job.steps||[]);
          }
        }catch(e){set("latest-step","詳細取得不可");}
      }else set("latest-state","ビルド履歴なし");
    }
    if(r2.status==="fulfilled")releases(r2.value);
    byId("fetch-error").hidden=r1.status==="fulfilled"&&r2.status==="fulfilled";
    set("fetched-at","更新 "+new Date().toLocaleTimeString("ja-JP",{timeZone:"Asia/Tokyo"}));
  }finally{busy=false;byId("refresh").disabled=false;}
}
byId("refresh").addEventListener("click",refresh);
document.addEventListener("visibilitychange",()=>{if(!document.hidden)refresh();});
refresh();setInterval(refresh,90000);
})();