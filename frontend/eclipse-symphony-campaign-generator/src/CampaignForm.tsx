/* eslint-disable @typescript-eslint/no-unused-vars */
import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import campaign from "./campaign/campaign.json";
import campaignUpgrade from "./campaign/campaign_upgrade.json";


type FormValues = {
  sourceVersion: string;
  targetVersion: string;
  targets: string[];
};

const SOFTWARE_VERSIONS = ["v1", "v2", "v3"];
const TARGETS = ["Fleet A", "Fleet B", "Fleet C"];

const CampaignForm: React.FC = () => {
  const { register, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      sourceVersion: SOFTWARE_VERSIONS[0],
      targetVersion: SOFTWARE_VERSIONS[1],
      targets: [],
    },
  });
  const [isCreating, setIsCreating] = useState(false);
  const [isActivating, setIsActivating] = useState(false);
  const [currentStatus, setCurrentStatus] = useState("Stopped");

  const onSubmit = async (data: FormValues) => {
    console.log("form data", data);
    // const campaignName = `canary-v-${data.targetVersion}`;
    const campaignName = campaign.metadata.name;

    // const body = {
    //   firstStage: "deploy-v1",
    //   selfDriving: true,
    //   stages: {
    //     "deploy-v1": {
    //       name: "Deploy Old Version",
    //       provider: "providers.stage.patch",
    //       inputs: {
    //         containerImage: `redis:${data.sourceVersion}`,
    //         targets: data.targets,
    //       },
    //       stageSelector: "",
    //     },
    //     "deploy-v2": {
    //       name: "Deploy New Version",
    //       provider: "providers.stage.patch",
    //       inputs: {
    //         containerImage: `redis:${data.targetVersion}`,
    //         targets: data.targets,
    //       },
    //       stageSelector: "",
    //     },
    //     "canary-traffic": {
    //       name: "Canary Traffic Shift",
    //       provider: "providers.stage.counter",
    //       inputs: {
    //         trafficPercentage: 10,
    //         targets: data.targets,
    //       },
    //       stageSelector: "",
    //     },
    //     "full-rollout": {
    //       name: "Full Traffic Shift",
    //       provider: "providers.stage.counter",
    //       inputs: {
    //         trafficPercentage: 100,
    //         targets: data.targets,
    //       },
    //       stageSelector: "",
    //     },
    //   },
    // };

    // const body = data.targetVersion === "v2" ? campaign : campaign2;

    // console.log("body", body);
    // console.log("body stringified", JSON.stringify(campaign));

    try {
      setIsCreating(true);
      const res = await fetch(
        `http://localhost:8082/v1alpha2/campaigns/payload-campaign-v-1`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoiYWRtaW4iLCJpc3MiOiJzeW1waG9ueSIsInN1YiI6InN5bXBob255IiwiYXVkIjpbIioiXSwiZXhwIjoxNzU5NDQyODA4LCJuYmYiOjE3NTkzNTY0MDgsImlhdCI6MTc1OTM1NjQwOCwianRpIjoiMSJ9.4XFVGMImLYEpn5FQzniOH1vmUXCqJkfn_p5VOfJcRRw`,
          },
          body: JSON.stringify(campaign),
        }
      );

      setTimeout(async () => {
        const res = await fetch(
          `http://localhost:8082/v1alpha2/activations/registry/payload-campaign-activation`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoiYWRtaW4iLCJpc3MiOiJzeW1waG9ueSIsInN1YiI6InN5bXBob255IiwiYXVkIjpbIioiXSwiZXhwIjoxNzU5NDQyODA4LCJuYmYiOjE3NTkzNTY0MDgsImlhdCI6MTc1OTM1NjQwOCwianRpIjoiMSJ9.4XFVGMImLYEpn5FQzniOH1vmUXCqJkfn_p5VOfJcRRw`,
            },
            body: JSON.stringify({
              "metadata": {
                  "name": "payload-campaign-activation"
              },
              "spec": {
                  "campaign": "payload-campaign-v-1",
                  "stage": "",
                  "inputs": {}
              }
          }),
          }
        );
      }, 1000);

      if (!res.ok) throw new Error(await res.text());
      const json = await res.json();
      console.log("✅ Campaign created:", json);
      alert("Campaign created successfully!");
    } catch (err) {
      console.error("❌ Error sending campaign:", err);
      alert("Error creating campaign");
    } finally {
      setIsCreating(false);
    }
  };

  const activateCampaign = async () => {
    console.log("activating campaign");
    try {
      setIsActivating(true);
      const res = await fetch(
        `http://localhost:8082/v1alpha2/campaigns/payload-campaign-1-v-1`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoiYWRtaW4iLCJpc3MiOiJzeW1waG9ueSIsInN1YiI6InN5bXBob255IiwiYXVkIjpbIioiXSwiZXhwIjoxNzU5NDQyODA4LCJuYmYiOjE3NTkzNTY0MDgsImlhdCI6MTc1OTM1NjQwOCwianRpIjoiMSJ9.4XFVGMImLYEpn5FQzniOH1vmUXCqJkfn_p5VOfJcRRw`,
          },
          body: JSON.stringify(campaignUpgrade),
        }
      );

      setTimeout(async () => {
        const res = await fetch(
          `http://localhost:8082/v1alpha2/activations/registry/payload-campaign-activation-1`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoiYWRtaW4iLCJpc3MiOiJzeW1waG9ueSIsInN1YiI6InN5bXBob255IiwiYXVkIjpbIioiXSwiZXhwIjoxNzU5NDQyODA4LCJuYmYiOjE3NTkzNTY0MDgsImlhdCI6MTc1OTM1NjQwOCwianRpIjoiMSJ9.4XFVGMImLYEpn5FQzniOH1vmUXCqJkfn_p5VOfJcRRw`,
            },
            body: JSON.stringify({
              "metadata": {
                  "name": "payload-campaign-activation-1"
              },
              "spec": {
                  "campaign": "payload-campaign-1-v-1",
                  "stage": "",
                  "inputs": {}
              }
          }),
          }
        );
      }, 1000);
    } catch (err) {
      console.error("❌ Error activating campaign:", err);
      alert("Error activating campaign");
    } finally {
      setIsActivating(false);
    }
  };

  useEffect(() => {
    let pollingInterval: number;

    if (isCreating || isActivating) {
      pollingInterval = setInterval(() => {
        fetch("/GET-CAMPAIGN-STATUS-ENDPOINT")
          .then((res) => res.json())
          .then((data) => {
            console.log("Polled data:", data);
            // setCurrentStatus()
          })
          .catch((err) => console.error("Polling error:", err));
      }, 3000);
    }

    return () => {
      if (pollingInterval) clearInterval(pollingInterval);
    };
  }, [isCreating, isActivating]);

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className="space-y-4 p-4 max-w-lg mx-auto"
    >
      <div>
        <label className="block font-medium">Source Version</label>
        <select
          {...register("sourceVersion")}
          className="border rounded p-2 w-full margin-left-right-m"
        >
          {SOFTWARE_VERSIONS.map((v) => (
            <option key={v} value={v}>
              {v}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="block font-medium">Target Version</label>
        <select
          {...register("targetVersion")}
          className="border rounded p-2 w-full margin-left-right-m"
        >
          {SOFTWARE_VERSIONS.map((v) => (
            <option key={v} value={v}>
              {v}
            </option>
          ))}
        </select>
      </div>

      {/* <div className="margin-top-bottom-l">
        Current Status: 
      </div> */}

      <div>
        <button
          type="submit"
          className="bg-green-600 text-white px-4 py-2 rounded margin-left-right-s"
          disabled={isCreating || isActivating}
        >
          🏗️ Canary Rollout
        </button>
        <button
          type="button"
          className="bg-green-600 text-white px-4 py-2 rounded margin-left-right-s"
          onClick={activateCampaign}
          disabled={isCreating || isActivating}
        >
          🚀 Canary Upgrade
        </button>
      </div>
    </form>
  );
};

export default CampaignForm;
