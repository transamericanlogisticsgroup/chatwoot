<script>
import { useVuelidate } from '@vuelidate/core';
import { useAccount } from 'dashboard/composables/useAccount';
import router from '../../../../index';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import instagramClient from 'dashboard/api/channel/instagramClient';

export default {
  mixins: [globalConfigMixin],
  setup() {
    const { accountId } = useAccount();
    return {
      accountId,
      v$: useVuelidate(),
    };
  },
  data() {
    return {
      isCreating: false,
      isRequestingAuthorization: false,
    };
  },

  validations: {},

  computed: {},

  methods: {
    async requestAuthorization() {
      this.isRequestingAuthorization = true;
      const response = await instagramClient.generateAuthorization();
      const {
        data: { url },
      } = response;

      window.location.href = url;
    },

    createChannel() {
      this.v$.$touch();
      if (!this.v$.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store
          .dispatch('inboxes/createFBChannel', this.channelParams())
          .then(data => {
            router.replace({
              name: 'settings_inboxes_add_agents',
              params: { page: 'new', inbox_id: data.id },
            });
          })
          .catch(() => {
            this.isCreating = false;
          });
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div class="flex flex-col items-center justify-center h-full text-center">
      <a href="#" @click="requestAuthorization()">
        <img
          class="w-auto h-10"
          src="~dashboard/assets/images/channels/facebook_login.png"
          alt="Facebook-logo"
        />
      </a>
    </div>
  </div>
</template>
