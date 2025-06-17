import { invoke } from "@tauri-apps/api/core";

import { ActivateSoftwareRequest } from "./type";

export const getSoftwareActivationQueryOptions = {
    queryKey: ["software-activation"],
    queryFn: async () => {
        const res = await invoke("is_software_activated");
        return res as boolean;
    },
};

export const getMachineCodeQueryOptions = {
    queryKey: ["get-machine-code"],
    queryFn: async () => {
        const res = await invoke("get_machine_code");
        return res as string;
    },
};

export const activateSoftwareMutationOptions = {
    mutationKey: ["software-activation"],
    mutationFn: async (data: ActivateSoftwareRequest) => {
        const res = await invoke("verify_license", { license: data.license });
        return res as boolean;
    },

};