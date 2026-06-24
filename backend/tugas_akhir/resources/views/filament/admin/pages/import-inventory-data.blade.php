<x-filament-panels::page>
    <form wire:submit.prevent="import" class="space-y-6">
        {{ $this->form }}

        <x-filament::button type="submit" icon="heroicon-o-arrow-up-tray">
            Import Data Inventory
        </x-filament::button>
    </form>
</x-filament-panels::page>